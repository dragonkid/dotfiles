#!/usr/bin/env python3
"""
Obsidian Vault Search
语义搜索 vault，返回最相关的笔记
用法: python3 vault_search.py "<query>" [--top 5]
"""
import os
import sys
import argparse
import subprocess
import time
import urllib.request
from pathlib import Path

import chromadb
import ollama
from ollama import Client as OllamaClient

VAULT = Path(os.path.realpath(Path.home() / "Documents/second-brain"))
DB_PATH = Path.home() / ".openclaw/workspace/.vault_chroma"
COLLECTION = "vault"
EMBED_MODEL = "bge-m3"
REMOTE_HOST = "http://192.168.1.100:11434"
LOCAL_HOST = "http://localhost:11434"
CHROMA_PORT = 8000


def ensure_chroma_server():
    try:
        urllib.request.urlopen(f"http://127.0.0.1:{CHROMA_PORT}/api/v2/heartbeat", timeout=2)
        return
    except Exception:
        pass
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
            return
        except Exception:
            pass
    raise RuntimeError("ChromaDB server 启动超时")


def _pick_ollama_client(prefer_local: bool = True) -> OllamaClient:
    hosts = [LOCAL_HOST, REMOTE_HOST] if prefer_local else [REMOTE_HOST, LOCAL_HOST]
    for host in hosts:
        try:
            c = OllamaClient(host=host, timeout=5.0)
            c.list()
            return c
        except Exception:
            continue
    raise RuntimeError("无法连接到任何 Ollama 实例")


client_ollama = None  # 延迟初始化


def search(query: str, top: int = 5, limit: int = 0):
    client = chromadb.HttpClient(host="127.0.0.1", port=8000)
    try:
        col = client.get_collection(COLLECTION, embedding_function=None)
    except Exception:
        print("索引不存在，请先运行 vault_index.py", file=sys.stderr)
        sys.exit(1)

    embedding = client_ollama.embeddings(model=EMBED_MODEL, prompt=query)["embedding"]
    results = col.query(query_embeddings=[embedding], n_results=top)

    docs = results["documents"][0]
    metas = results["metadatas"][0]
    distances = results["distances"][0]
    # 将 L2 距离转为相对相关度（排名内归一化）
    max_dist = max(distances) if distances else 1
    min_dist = min(distances) if distances else 0
    drange = max_dist - min_dist or 1

    for i, (doc, meta, dist) in enumerate(zip(docs, metas, distances)):
        score = round((1 - (dist - min_dist) / drange) * 100, 1)
        path = meta["file"]
        excerpt = doc[:limit].replace("\n", " ").strip() + "..." if limit > 0 else doc
        print(f"\n[{i+1}] {path} (相关度 {score}%)")
        print(f"    {excerpt}")
        images = meta.get("images", "")
        if images:
            print(f"    [images: {images}]")


def main():
    global client_ollama
    parser = argparse.ArgumentParser()
    parser.add_argument("query", help="搜索关键词")
    parser.add_argument("--top", type=int, default=5, help="返回结果数量")
    parser.add_argument("--limit", type=int, default=0, help="截断每条结果的字符数（默认0=完整输出）")
    args = parser.parse_args()
    client_ollama = _pick_ollama_client(prefer_local=True)
    ensure_chroma_server()
    search(args.query, args.top, args.limit)

if __name__ == "__main__":
    main()
