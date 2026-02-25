#!/usr/bin/env python3
"""
Obsidian Vault Search
语义搜索 vault，返回最相关的笔记
用法: python3 vault_search.py "<query>" [--top 5]
"""
import os
import sys
import argparse
from pathlib import Path

import chromadb
import ollama
from ollama import Client as OllamaClient

VAULT = Path(os.path.realpath(Path.home() / "Documents/second-brain"))
DB_PATH = Path.home() / ".openclaw/workspace/.vault_chroma"
COLLECTION = "vault"
EMBED_MODEL = "nomic-embed-text"
REMOTE_HOST = "http://192.168.1.100:11434"
LOCAL_HOST = "http://localhost:11434"


def _pick_ollama_client(prefer_local: bool = False) -> OllamaClient:
    hosts = [LOCAL_HOST, REMOTE_HOST] if prefer_local else [REMOTE_HOST, LOCAL_HOST]
    for host in hosts:
        try:
            c = OllamaClient(host=host)
            c.list()
            return c
        except Exception:
            continue
    raise RuntimeError("无法连接到任何 Ollama 实例")


client_ollama = _pick_ollama_client(prefer_local=True)  # embedding 优先本地


def search(query: str, top: int = 5):
    client = chromadb.PersistentClient(path=str(DB_PATH))
    try:
        col = client.get_collection(COLLECTION)
    except Exception:
        print("索引不存在，请先运行 vault_index.py", file=sys.stderr)
        sys.exit(1)

    embedding = client_ollama.embeddings(model=EMBED_MODEL, prompt=query)["embedding"]
    results = col.query(query_embeddings=[embedding], n_results=top)

    docs = results["documents"][0]
    metas = results["metadatas"][0]
    distances = results["distances"][0]

    for i, (doc, meta, dist) in enumerate(zip(docs, metas, distances)):
        score = round((1 - dist) * 100, 1)
        path = meta["path"]
        # 取前 300 字作为摘要
        excerpt = doc[:300].replace("\n", " ").strip()
        print(f"\n[{i+1}] {path} (相关度 {score}%)")
        print(f"    {excerpt}...")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("query", help="搜索关键词")
    parser.add_argument("--top", type=int, default=5, help="返回结果数量")
    args = parser.parse_args()
    search(args.query, args.top)
