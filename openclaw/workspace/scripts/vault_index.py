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
import logging
import json
import base64
warnings.filterwarnings("ignore")
logging.getLogger("pypdf").setLevel(logging.ERROR)
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


def _pick_ollama_client(prefer_local: bool = False, remote_host: str = None) -> OllamaClient:
    """prefer_local=True 时优先本地，否则优先远程"""
    remote = remote_host or REMOTE_HOST
    hosts = [LOCAL_HOST, remote] if prefer_local else [remote, LOCAL_HOST]
    for host in hosts:
        try:
            c = OllamaClient(host=host)
            c.list()
            print(f"Ollama: 使用 {host}")
            return c
        except Exception:
            continue
    raise RuntimeError("无法连接到任何 Ollama 实例（远程或本地）")


embed_client = None  # 延迟初始化，在 main 或首次使用时设置

CHUNK_SIZE = 1800
CHUNK_OVERLAP = 200
MIN_CHUNK_SIZE = 300  # 小于此值的 chunk 合并到相邻 chunk
CONCURRENCY = 4   # 并发 chunk 处理数
BATCH_SIZE = 16   # ChromaDB 批量写入大小
SKIP_DIRS = {".obsidian", ".claude", ".git", ".trash", "Attachments"}
SKIP_SUFFIXES = {".excalidraw.md"}
SUPPORTED_EXTS = {".md", ".pdf"}
PDF_MAX_PAGES = 15  # PDF 最多读取有效页数（跳过的不计入）

IMAGE_CACHE_PATH = Path.home() / ".openclaw/workspace/.image_analysis_cache.json"
IMAGE_MAX_BYTES = 5 * 1024 * 1024  # 5MB，超过跳过
OPENCLAW_CONFIG = Path.home() / ".openclaw/openclaw.json"


# ── 图片分析 ──────────────────────────────────────────────────────────────────

def load_image_cache() -> dict:
    if IMAGE_CACHE_PATH.exists():
        try:
            return json.loads(IMAGE_CACHE_PATH.read_text())
        except Exception:
            return {}
    return {}


def save_image_cache(cache: dict):
    try:
        IMAGE_CACHE_PATH.write_text(json.dumps(cache, ensure_ascii=False, indent=2))
    except Exception:
        pass


def get_vision_client() -> dict | None:
    """从 OpenClaw 配置读取默认供应商的 API 信息"""
    try:
        config = json.loads(OPENCLAW_CONFIG.read_text())
        primary = config.get("agents", {}).get("defaults", {}).get("model", {}).get("primary", "")
        if "/" not in primary:
            return None
        provider_name, model_id = primary.split("/", 1)
        p = config.get("models", {}).get("providers", {}).get(provider_name)
        if not p:
            return None
        return {
            "base_url": p["baseUrl"],
            "api_key": p["apiKey"],
            "model": model_id,
        }
    except Exception as e:
        print(f"[vision] 读取配置失败: {e}")
    return None


def analyze_image_with_claude(image_path: Path, client: dict, max_retries: int = 3, retry_delay: float = 5.0) -> str:
    """调用 Anthropic Messages API 分析图片（使用 requests 库）"""
    if image_path.stat().st_size > IMAGE_MAX_BYTES:
        return "[图片过大，跳过分析]"
    suffix = image_path.suffix.lower()
    media_map = {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
                 ".gif": "image/gif", ".webp": "image/webp"}
    media_type = media_map.get(suffix, "image/png")
    image_data = base64.standard_b64encode(image_path.read_bytes()).decode()
    import requests as _requests
    last_err = None
    for attempt in range(1, max_retries + 1):
        try:
            resp = _requests.post(
                f"{client['base_url']}/v1/messages",
                json={
                    "model": client["model"],
                    "max_tokens": 4096,
                    "messages": [{
                        "role": "user",
                        "content": [
                            {"type": "image", "source": {"type": "base64", "media_type": media_type, "data": image_data}},
                            {"type": "text", "text": (
                                "请详细分析这张图片，提取所有可见信息，**不要伪造图片中不存在的信息**：\n"
                                "1. 如果是监控/图表类图片：图表标题（title）、每个 Legend 项的名称及对应数值（均值/峰值/当前值等）、坐标轴单位、时间范围。\n"
                                "2. 如果是截图/界面类图片：所有可见文字、按钮、菜单项、状态信息。\n"
                                "3. 如果是文档/表格类图片：标题、所有行列数据、关键结论。\n"
                                "4. 如果是代码/命令类图片：完整代码或命令内容。\n"
                                "5. 通用：任何数字、错误信息、高亮内容都不要遗漏。\n\n"
                                "**重要格式要求：**\n"
                                "在每个独立的信息单元之间插入分隔标记 `<!-- SPLIT -->`，每个单元用 `## 标题` 开头。\n"
                                "根据图片类型选择合适的拆分粒度：\n"
                                "- 监控面板/仪表盘：每个图表/面板为一个单元\n"
                                "- 代码/命令截图：每个函数或功能模块为一个单元\n"
                                "- 文档/文章截图：每个章节或段落为一个单元\n"
                                "- 表格截图：每个逻辑分组为一个单元\n"
                                "- 界面截图：每个功能区域为一个单元\n"
                                "- 架构图/流程图：每个组件或阶段为一个单元\n"
                                "- 最后的总结/观察也作为独立单元\n\n"
                                "用中文回答。"
                            )}
                        ]
                    }]
                },
                headers={
                    "Authorization": f"Bearer {client['api_key']}",
                    "anthropic-version": "2023-06-01",
                },
                timeout=120
            )
            resp.raise_for_status()
            return resp.json()["content"][0]["text"]
        except Exception as e:
            last_err = e
            if attempt < max_retries:
                print(f"    [vision] 第{attempt}次失败: {e}，{retry_delay}s 后重试...")
                time.sleep(retry_delay)
            else:
                print(f"    [vision] 已重试 {max_retries} 次，放弃")
    raise last_err


def find_image_file(image_name: str) -> Path | None:
    """在 vault 中查找图片，优先 Attachments/"""
    p = VAULT / "Attachments" / image_name
    if p.exists():
        return p
    for f in VAULT.rglob(image_name):
        return f
    return None


def enrich_text_with_images(text: str, image_cache: dict, vision_client: dict | None) -> tuple[str, list[str]]:
    """将 ![[img]] 替换为 Claude 分析结果，返回 (enriched_text, [rel_image_paths])
    vision_client=None 时仍查 cache，只是不触发新的分析。
    """
    image_paths: list[str] = []

    def replace_image(match):
        img_name = match.group(1)
        img_file = find_image_file(img_name)
        if img_file is None:
            print(f"\n    [vision] ⚠ 找不到图片: {img_name}")
            return match.group(0)
        rel = str(img_file.relative_to(VAULT))
        if rel not in image_paths:
            image_paths.append(rel)
        img_hash = file_hash(img_file)
        size_kb = img_file.stat().st_size // 1024
        if img_hash in image_cache:
            analysis = image_cache[img_hash]
            print(f"\n    [vision] ✓ 缓存命中: {img_name} ({size_kb}KB)")
            return f"[图片: {img_name}]\n{analysis}"
        elif vision_client is not None:
            print(f"\n    [vision] → 触发解析: {img_name} ({size_kb}KB) ...", flush=True)
            try:
                analysis = analyze_image_with_claude(img_file, vision_client)
                image_cache[img_hash] = analysis
                save_image_cache(image_cache)
                print(f"    [vision] 解析完成: {img_name}")
                return f"[图片: {img_name}]\n{analysis}"
            except Exception as e:
                print(f"    [vision] 解析失败: {img_name} → {e}")
                return match.group(0)
        else:
            print(f"\n    [vision] ⊘ 无缓存且无 vision client，跳过: {img_name}")
            return match.group(0)

    enriched = re.sub(
        r'!\[\[([^\]]+\.(?:png|jpg|jpeg|gif|webp))\]\]',
        replace_image, text, flags=re.IGNORECASE
    )
    return enriched, image_paths


# ── 分块 ──────────────────────────────────────────────────────────────────────

SKIP_PDF_SECTIONS = {"acknowledgment", "acknowledgements", "dedication", "致谢", "献给"}


def clean_pdf_text(text: str) -> str:
    """清理 PDF 提取文本：压缩多余空格、规范换行"""
    text = re.sub(r' {2,}', ' ', text)       # 多余空格
    text = re.sub(r'\n{3,}', '\n\n', text)   # 多余空行
    return text.strip()


def is_skip_section(text: str) -> bool:
    """判断是否为致谢/献词等不重要章节"""
    first_line = text.strip().split('\n')[0].strip().lower()
    return any(kw in first_line for kw in SKIP_PDF_SECTIONS)


def extract_text(f: Path) -> str:
    """提取文件文本，支持 .md 和 .pdf"""
    if f.suffix == ".pdf":
        try:
            reader = PdfReader(str(f))
            parts = []
            valid_count = 0
            for p in reader.pages:
                if valid_count >= PDF_MAX_PAGES:
                    break
                t = p.extract_text() or ""
                t = clean_pdf_text(t)
                if not t:
                    continue
                if is_skip_section(t):
                    continue  # 跳过不计入配额
                parts.append(t)
                valid_count += 1
            return "\n\n".join(parts)
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


def make_chunks(file_path: str, text: str, images: list[str] | None = None) -> list[dict]:
    """生成所有 chunks，每个 chunk 包含 heading_path、content 和 images。
    图片分析内容单独作为完整 chunk，不参与普通分块。
    """
    images_str = ",".join(images) if images else ""

    # 先把图片分析块提取出来，替换为占位符
    image_chunks = []
    image_pattern = re.compile(r'\[图片: ([^\]]+)\]\n(.*?)(?=\n\[图片: |\Z)', re.DOTALL)

    def extract_image(m):
        img_name = m.group(1)
        analysis = m.group(2).strip()
        if analysis:
            image_chunks.append({
                "file": file_path,
                "heading": f"图片分析: {img_name}",
                "content": f"[图片: {img_name}]\n{analysis}",
                "images": img_name,
            })
        return ""  # 从主文本中移除

    clean_text = image_pattern.sub(extract_image, text)

    # 对剩余文本正常分块
    heading_chunks = split_by_headings(clean_text)
    result = []
    for heading_path, content in heading_chunks:
        if len(content) <= CHUNK_SIZE:
            result.append({"file": file_path, "heading": heading_path, "content": content, "images": images_str})
        else:
            for sub in split_fixed(content):
                result.append({"file": file_path, "heading": heading_path, "content": sub, "images": images_str})
    if not result:
        for sub in split_fixed(clean_text):
            result.append({"file": file_path, "heading": "", "content": sub, "images": images_str})

    # 对图片分析 chunk 按 <!-- SPLIT --> 标记拆分为独立单元
    split_image_chunks = []
    for ic in image_chunks:
        content = ic["content"]
        sections = [s.strip() for s in content.split('<!-- SPLIT -->') if s.strip()] \
            if '<!-- SPLIT -->' in content else [content]

        if len(sections) <= 1 and len(content) <= CHUNK_SIZE:
            split_image_chunks.append(ic)
        elif len(sections) <= 1:
            # 无标记且超长，按 CHUNK_SIZE 硬切
            for sub in split_fixed(content):
                split_image_chunks.append({
                    "file": ic["file"],
                    "heading": ic["heading"],
                    "content": sub,
                    "images": ic["images"],
                })
        else:
            for sec in sections:
                if not sec:
                    continue
                first_line = sec.split('\n', 1)[0].lstrip('#').strip()
                sub_heading = f"{ic['heading']} > {first_line}" if first_line else ic['heading']
                if len(sec) <= CHUNK_SIZE:
                    split_image_chunks.append({
                        "file": ic["file"],
                        "heading": sub_heading,
                        "content": sec,
                        "images": ic["images"],
                    })
                else:
                    for sub in split_fixed(sec):
                        split_image_chunks.append({
                            "file": ic["file"],
                            "heading": sub_heading,
                            "content": sub,
                            "images": ic["images"],
                        })

    return merge_short_chunks(result) + split_image_chunks


# ── Embedding ─────────────────────────────────────────────────────────────────

def build_doc_text(chunk: dict) -> str:
    parts = []
    if chunk["heading"]:
        parts.append(f"[文件: {chunk['file']} | 章节: {chunk['heading']}]")
    else:
        parts.append(f"[文件: {chunk['file']}]")
    parts.append(chunk["content"])
    return "\n".join(parts)

def get_embedding(text: str, client=None) -> list[float]:
    c = client or embed_client
    for attempt in range(3):
        try:
            resp = c.embeddings(model=EMBED_MODEL, prompt=text[:4000])
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


def index_vault(reset: bool = False, dry_run: bool = False, single_file: str = None, no_vision: bool = False, reset_image_cache: bool = False, ollama_client=None):
    client = chromadb.HttpClient(host="127.0.0.1", port=8000)

    # 视觉模型客户端
    vision_client = None if no_vision else get_vision_client()
    if vision_client:
        print(f"视觉分析: {vision_client['base_url']} / {vision_client['model']}")

    if reset:
        try:
            client.delete_collection(COLLECTION)
            print("已清空旧索引")
        except Exception:
            pass
    if reset_image_cache:
        if IMAGE_CACHE_PATH.exists():
            IMAGE_CACHE_PATH.unlink()
            print("已清空图片分析缓存")

    image_cache = load_image_cache()  # 清空后再加载

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

        # 图片分析：将 ![[img]] 替换为 Claude 描述，Clippings 目录跳过
        vc = None if rel.startswith("Clippings/") else vision_client
        text, img_paths = enrich_text_with_images(text, image_cache, vc)

        chunks = make_chunks(rel, text, images=img_paths)
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
                "images": chunk.get("images", ""),
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


def main():
    global embed_client
    parser = argparse.ArgumentParser()
    parser.add_argument("--reset", action="store_true", help="清空重建索引")
    parser.add_argument("--reset-image-cache", action="store_true", help="清空图片分析缓存（改了 prompt 后用）")
    parser.add_argument("--dry-run", action="store_true", help="只显示分块结果，不写入")
    parser.add_argument("--file", type=str, default=None, help="只索引指定文件（相对 vault 路径）")
    parser.add_argument("--no-vision", action="store_true", help="跳过图片分析")
    parser.add_argument("--remote", type=str, default=None, help="Ollama remote host，如 http://192.168.1.200:11434")
    args = parser.parse_args()
    if args.remote:
        embed_client = _pick_ollama_client(prefer_local=False, remote_host=args.remote)
    else:
        embed_client = _pick_ollama_client(prefer_local=False)
    if not args.dry_run:
        ensure_chroma_server()
    index_vault(reset=args.reset, dry_run=args.dry_run, single_file=args.file, no_vision=args.no_vision, reset_image_cache=args.reset_image_cache)

if __name__ == "__main__":
    main()
