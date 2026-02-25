#!/usr/bin/env python3
"""
Obsidian Vault Indexer - Contextual Chunking
用法: python3 vault_index.py [--reset] [--dry-run]
"""
import os
import sys
import hashlib
import argparse
import re
import time
import subprocess
import urllib.request
import warnings
warnings.filterwarnings("ignore")
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

import chromadb
import ollama
from ollama import Client as OllamaClient
from pypdf import PdfReader

VAULT = Path(os.path.realpath(Path.home() / "Documents/second-brain"))
DB_PATH = Path.home() / ".openclaw/workspace/.vault_chroma"
COLLECTION = "vault"
EMBED_MODEL = "bge-m3"
REMOTE_HOST = "http://192.168.1.100:11434"
LOCAL_HOST = "http://localhost:11434"
CHROMA_PORT = 8000


def ensure_chroma_server():
    """确保 ChromaDB server 在运行，没有则自动启动（uvx Python 3.11）"""
    try:
        urllib.request.urlopen(f"http://127.0.0.1:{CHROMA_PORT}/api/v2/heartbeat", timeout=2)
        return
    except Exception:
        pass
    print("启动 ChromaDB server...")
    log_path = Path.home() / ".openclaw/workspace/logs/chroma-server.log"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with open(log_path, "a") as log:
        subprocess.Popen(
            ["uvx", "--python", "3.11", "--from", "chromadb==1.5.1",
             "chroma", "run", "--path", str(DB_PATH),
             "--host", "127.0.0.1", "--port", str(CHROMA_PORT)],
            stdout=log, stderr=log, start_new_session=True
        )
    for _ in range(30):
        time.sleep(1)
        try:
            urllib.request.urlopen(f"http://127.0.0.1:{CHROMA_PORT}/api/v2/heartbeat", timeout=2)
            print("ChromaDB server 已就绪")
            return
        except Exception:
            pass
    raise RuntimeError("ChromaDB server 启动超时")


def _pick_ollama_client(prefer_local: bool = False) -> OllamaClient:
    """prefer_local=True 时优先本地，否则优先远程"""
    hosts = [LOCAL_HOST, REMOTE_HOST] if prefer_local else [REMOTE_HOST, LOCAL_HOST]
    for host in hosts:
        try:
            c = OllamaClient(host=host)
            c.list()
            print(f"Ollama: 使用 {host}")
            return c
        except Exception:
            continue
    raise RuntimeError("无法连接到任何 Ollama 实例（远程或本地）")


embed_client = _pick_ollama_client(prefer_local=False)  # embedding 优先远程

CHUNK_SIZE = 1800
CHUNK_OVERLAP = 200
MIN_CHUNK_SIZE = 300  # 小于此值的 chunk 合并到相邻 chunk
CONCURRENCY = 4   # 并发 chunk 处理数
BATCH_SIZE = 16   # ChromaDB 批量写入大小
SKIP_DIRS = {".obsidian", ".claude", ".git", ".trash", "Attachments"}
SKIP_SUFFIXES = {".excalidraw.md"}
SUPPORTED_EXTS = {".md", ".pdf"}
PDF_MAX_PAGES = 10  # PDF 只索引前 N 页


# ── 分块 ──────────────────────────────────────────────────────────────────────

def extract_text(f: Path) -> str:
    """提取文件文本，支持 .md 和 .pdf"""
    if f.suffix == ".pdf":
        try:
            reader = PdfReader(str(f))
            pages = reader.pages[:PDF_MAX_PAGES]
            return "\n\n".join(p.extract_text() or "" for p in pages)
        except Exception:
            return ""
    return f.read_text(errors="ignore")


def split_by_headings(text: str) -> list[tuple[str, str]]:
    """按标题分块，返回 [(heading_path, content), ...]"""
    lines = text.split("\n")
    chunks = []
    current_headings = [""] * 6  # h1-h6
    current_lines = []

    for line in lines:
        m = re.match(r"^(#{1,6})\s+(.*)", line)
        if m:
            if current_lines:
                content = "\n".join(current_lines).strip()
                if content:
                    path = " > ".join(h for h in current_headings if h)
                    chunks.append((path, content))
            level = len(m.group(1)) - 1
            current_headings[level] = m.group(2).strip()
            current_headings[level + 1:] = [""] * (5 - level)
            current_lines = [line]
        else:
            current_lines.append(line)

    if current_lines:
        content = "\n".join(current_lines).strip()
        if content:
            path = " > ".join(h for h in current_headings if h)
            chunks.append((path, content))

    return chunks


def split_fixed(text: str, size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> list[str]:
    """固定大小滑动窗口分块"""
    chunks = []
    start = 0
    while start < len(text):
        chunks.append(text[start:start + size])
        start += size - overlap
    return chunks


def merge_short_chunks(chunks: list[dict], min_size: int = MIN_CHUNK_SIZE) -> list[dict]:
    """合并过短的相邻 chunk（同一 heading 下）"""
    if not chunks:
        return chunks
    merged = []
    buf = chunks[0].copy()
    for chunk in chunks[1:]:
        # 同文件同 heading 且 buf 太短，合并
        if (buf["file"] == chunk["file"]
                and buf["heading"] == chunk["heading"]
                and len(buf["content"]) < min_size):
            buf["content"] = buf["content"] + "\n\n" + chunk["content"]
        else:
            if len(buf["content"]) >= min_size or not merged:
                merged.append(buf)
            else:
                # buf 仍然太短，合并到上一个
                merged[-1]["content"] += "\n\n" + buf["content"]
            buf = chunk.copy()
    # 处理最后一个
    if len(buf["content"]) >= min_size or not merged:
        merged.append(buf)
    else:
        merged[-1]["content"] += "\n\n" + buf["content"]
    return merged


def make_chunks(file_path: str, text: str) -> list[dict]:
    """生成所有 chunks，每个 chunk 包含 heading_path 和 content"""
    heading_chunks = split_by_headings(text)
    result = []
    for heading_path, content in heading_chunks:
        if len(content) <= CHUNK_SIZE:
            result.append({"file": file_path, "heading": heading_path, "content": content})
        else:
            for sub in split_fixed(content):
                result.append({"file": file_path, "heading": heading_path, "content": sub})
    if not result:
        for sub in split_fixed(text):
            result.append({"file": file_path, "heading": "", "content": sub})
    return merge_short_chunks(result)


# ── Embedding ─────────────────────────────────────────────────────────────────

def build_doc_text(chunk: dict) -> str:
    parts = []
    if chunk["heading"]:
        parts.append(f"[文件: {chunk['file']} | 章节: {chunk['heading']}]")
    else:
        parts.append(f"[文件: {chunk['file']}]")
    parts.append(chunk["content"])
    return "\n".join(parts)

def get_embedding(text: str) -> list[float]:
    for attempt in range(3):
        try:
            resp = embed_client.embeddings(model=EMBED_MODEL, prompt=text[:4000])
            return resp["embedding"]
        except Exception:
            if attempt == 2:
                raise
            time.sleep(2)
    return []


# ── 主流程 ────────────────────────────────────────────────────────────────────

def file_hash(path: Path) -> str:
    try:
        return hashlib.md5(path.read_bytes()).hexdigest()
    except OSError:
        return ""


def index_vault(reset: bool = False, dry_run: bool = False, single_file: str = None):
    client = chromadb.HttpClient(host="127.0.0.1", port=8000)

    if reset:
        try:
            client.delete_collection(COLLECTION)
            print("已清空旧索引")
        except Exception:
            pass

    col = client.get_or_create_collection(COLLECTION, embedding_function=None)

    if single_file:
        # 只索引单个文件
        f = VAULT / single_file
        md_files = [f] if f.exists() else []
    else:
        md_files = [
            f for f in VAULT.rglob("*")
            if f.suffix in SUPPORTED_EXTS
            and not any(skip in f.parts for skip in SKIP_DIRS)
            and not any(f.name.endswith(s) for s in SKIP_SUFFIXES)
        ]
    print(f"发现 {len(md_files)} 个文件")

    added = skipped = errors = 0

    # 清理已删除文件的索引（单文件模式跳过）
    if not single_file:
        all_indexed = col.get(include=["metadatas"])
        indexed_files = {m["file"] for m in all_indexed["metadatas"]} if all_indexed["metadatas"] else set()
        current_files = {str(f.relative_to(VAULT)) for f in md_files}
        deleted = indexed_files - current_files
        if deleted:
            for dead_file in deleted:
                old = col.get(where={"file": dead_file})
                if old["ids"]:
                    col.delete(ids=old["ids"])
            print(f"清理已删除文件：{len(deleted)} 个")
    for f in md_files:
        rel = str(f.relative_to(VAULT))

        try:
            text = extract_text(f)
        except OSError:
            skipped += 1
            continue

        if not text.strip():
            skipped += 1
            continue

        fhash = file_hash(f)
        # 检查文件是否已索引且未变更（用第一个 chunk 的 id 检查）
        first_id = hashlib.md5(f"{rel}:0".encode()).hexdigest()
        existing = col.get(ids=[first_id])
        if existing["ids"] and existing["metadatas"][0].get("hash") == fhash:
            skipped += 1
            continue

        chunks = make_chunks(rel, text)
        if dry_run:
            print(f"  {rel}: {len(chunks)} chunks")
            continue

        print(f"  {rel}: {len(chunks)} chunks", end="", flush=True)

        # 删除该文件旧的所有 chunks
        old = col.get(where={"file": rel})
        if old["ids"]:
            col.delete(ids=old["ids"])

        def process_chunk(args):
            i, chunk = args
            doc_text = build_doc_text(chunk)
            embedding = get_embedding(doc_text)
            chunk_id = hashlib.md5(f"{rel}:{i}".encode()).hexdigest()
            return chunk_id, doc_text, embedding, {
                "file": rel,
                "heading": chunk["heading"],
                "hash": fhash,
                "chunk_index": i,
            }

        # 并发处理 chunks，批量写入
        batch_ids, batch_docs, batch_embs, batch_metas = [], [], [], []
        with ThreadPoolExecutor(max_workers=CONCURRENCY) as ex:
            futures = {ex.submit(process_chunk, (i, c)): i for i, c in enumerate(chunks)}
            for fut in as_completed(futures):
                try:
                    cid, doc, emb, meta = fut.result()
                    batch_ids.append(cid)
                    batch_docs.append(doc)
                    batch_embs.append(emb)
                    batch_metas.append(meta)
                    print(".", end="", flush=True)
                    if len(batch_ids) >= BATCH_SIZE:
                        col.upsert(ids=batch_ids, embeddings=batch_embs,
                                   documents=batch_docs, metadatas=batch_metas)
                        batch_ids, batch_docs, batch_embs, batch_metas = [], [], [], []
                except Exception:
                    print("✗", end="", flush=True)
                    errors += 1

        if batch_ids:
            col.upsert(ids=batch_ids, embeddings=batch_embs,
                       documents=batch_docs, metadatas=batch_metas)

        print(f" ✓")
        added += 1

    print(f"\n完成：处理 {added} 个文件，跳过 {skipped}，chunk 错误 {errors}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--reset", action="store_true", help="清空重建索引")
    parser.add_argument("--dry-run", action="store_true", help="只显示分块结果，不写入")
    parser.add_argument("--file", type=str, default=None, help="只索引指定文件（相对 vault 路径）")
    args = parser.parse_args()
    if not args.dry_run:
        ensure_chroma_server()
    index_vault(reset=args.reset, dry_run=args.dry_run, single_file=args.file)
