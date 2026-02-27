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

import re
import chromadb
import ollama
from ollama import Client as OllamaClient
from rank_bm25 import BM25Okapi

VAULT = Path(os.path.realpath(Path.home() / "Documents/second-brain"))
DB_PATH = Path.home() / ".openclaw/workspace/.vault_chroma"
COLLECTION = "vault"
EMBED_MODEL = "bge-m3"
REMOTE_HOST = "http://192.168.1.11:11434"
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


def tokenize(text: str) -> list[str]:
    """简单中英文分词：中文按字，英文/数字按词"""
    tokens = re.findall(r'[a-zA-Z0-9]+(?:\.[0-9]+)?|[\u4e00-\u9fff]', text.lower())
    return tokens


def search(query: str, top: int = 5, limit: int = 0, bm25_weight: float = 0.3):
    client = chromadb.HttpClient(host="127.0.0.1", port=8000)
    try:
        col = client.get_collection(COLLECTION, embedding_function=None)
    except Exception:
        print("索引不存在，请先运行 vault_index.py", file=sys.stderr)
        sys.exit(1)

    # 向量搜索：取 top*3 候选
    n_candidates = min(top * 3, col.count())
    embedding = client_ollama.embeddings(model=EMBED_MODEL, prompt=query)["embedding"]
    vec_results = col.query(query_embeddings=[embedding], n_results=n_candidates)

    vec_docs = vec_results["documents"][0]
    vec_metas = vec_results["metadatas"][0]
    vec_distances = vec_results["distances"][0]
    vec_ids = vec_results["ids"][0]

    # cosine distance → cosine similarity: sim = 1 - distance
    # 范围 [0, 1]，越高越相关
    COSINE_DIST_THRESHOLD = 0.5  # cosine distance > 0.5 视为低置信度
    vec_sims = [1 - d for d in vec_distances]

    # BM25 搜索：在候选集上计算
    corpus = [tokenize(doc) for doc in vec_docs]
    query_tokens = tokenize(query)
    bm25 = BM25Okapi(corpus)
    bm25_scores = bm25.get_scores(query_tokens)

    # BM25 归一化到 [0, 1]
    bm25_max = max(bm25_scores) if max(bm25_scores) > 0 else 1
    bm25_norm = [s / bm25_max for s in bm25_scores]

    # 混合分数：向量用绝对 cosine similarity，BM25 用归一化分数
    alpha = 1 - bm25_weight  # 向量权重
    combined = []
    for i in range(len(vec_docs)):
        score = alpha * vec_sims[i] + bm25_weight * bm25_norm[i]
        combined.append((score, i))

    combined.sort(reverse=True)

    for rank, (score, i) in enumerate(combined[:top]):
        doc = vec_docs[i]
        meta = vec_metas[i]
        path = meta["file"]
        cosine_dist = vec_distances[i]
        display_score = round(score * 100, 1)
        low_confidence = cosine_dist > COSINE_DIST_THRESHOLD
        tag = " ⚠️ 低置信度" if low_confidence else ""
        excerpt = doc[:limit].replace("\n", " ").strip() + "..." if limit > 0 else doc
        print(f"\n[{rank+1}] {path} (相关度 {display_score}%{tag})")
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
    parser.add_argument("--bm25-weight", type=float, default=0.3, help="BM25 权重（0=纯向量，1=纯BM25，默认0.3）")
    args = parser.parse_args()
    client_ollama = _pick_ollama_client(prefer_local=False)
    ensure_chroma_server()
    search(args.query, args.top, args.limit, args.bm25_weight)

if __name__ == "__main__":
    main()
