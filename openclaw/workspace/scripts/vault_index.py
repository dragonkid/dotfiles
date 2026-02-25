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
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

import chromadb
import ollama
from ollama import Client as OllamaClient

VAULT = Path(os.path.realpath(Path.home() / "Documents/second-brain"))
DB_PATH = Path.home() / ".openclaw/workspace/.vault_chroma"
COLLECTION = "vault"
EMBED_MODEL = "nomic-embed-text"
CONTEXT_MODEL = "qwen2.5:latest"
REMOTE_HOST = "http://192.168.1.100:11434"
LOCAL_HOST = "http://localhost:11434"


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
context_client = _pick_ollama_client(prefer_local=False) # context 生成优先远程
SKIP_DIRS = {".obsidian", ".claude", ".git", ".trash"}
CHUNK_SIZE = 1200
CHUNK_OVERLAP = 200
CONCURRENCY = 4   # 并发 chunk 处理数
BATCH_SIZE = 16   # ChromaDB 批量写入大小


# ── 分块 ──────────────────────────────────────────────────────────────────────

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
    return result


# ── Contextual Chunking ───────────────────────────────────────────────────────

CONTEXT_PROMPT = """以下是一篇笔记的片段。请用一句话（不超过50字）描述这个片段在整篇文档中的作用和主题，帮助理解其上下文。只输出这一句话，不要解释。

文件：{file}
章节：{heading}
片段内容：
{content}

上下文描述："""


def generate_context(chunk: dict) -> str:
    prompt = CONTEXT_PROMPT.format(
        file=chunk["file"],
        heading=chunk["heading"] or "（无标题）",
        content=chunk["content"][:600],
    )
    for attempt in range(3):
        try:
            resp = context_client.generate(model=CONTEXT_MODEL, prompt=prompt, options={"num_predict": 80})
            return resp["response"].strip()
        except Exception as e:
            if attempt == 2:
                return ""
            time.sleep(2)
    return ""


def build_contextual_text(chunk: dict, context: str) -> str:
    parts = []
    if context:
        parts.append(f"[{context}]")
    if chunk["heading"]:
        parts.append(f"[文件: {chunk['file']} | 章节: {chunk['heading']}]")
    else:
        parts.append(f"[文件: {chunk['file']}]")
    parts.append(chunk["content"])
    return "\n".join(parts)


# ── Embedding ─────────────────────────────────────────────────────────────────

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
    client = chromadb.PersistentClient(path=str(DB_PATH))

    if reset:
        try:
            client.delete_collection(COLLECTION)
            print("已清空旧索引")
        except Exception:
            pass

    col = client.get_or_create_collection(COLLECTION)

    if single_file:
        # 只索引单个文件
        f = VAULT / single_file
        md_files = [f] if f.exists() else []
    else:
        md_files = [
            f for f in VAULT.rglob("*.md")
            if not any(skip in f.parts for skip in SKIP_DIRS)
        ]
    print(f"发现 {len(md_files)} 个 md 文件")

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
            text = f.read_text(errors="ignore")
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
            context = generate_context(chunk)
            contextual_text = build_contextual_text(chunk, context)
            embedding = get_embedding(contextual_text)
            chunk_id = hashlib.md5(f"{rel}:{i}".encode()).hexdigest()
            return chunk_id, contextual_text, embedding, {
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
    index_vault(reset=args.reset, dry_run=args.dry_run, single_file=args.file)
