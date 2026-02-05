---
name: fastapi-lifespan-di
description: Use when building FastAPI applications with async resources like HTTP clients or database connections that need proper lifecycle management with type-safe dependency injection to route handlers.
---

# FastAPI Lifespan + Dependency Injection

## Overview
Manage async resource lifecycle (HTTP clients, database connections) with clean initialization and shutdown, while providing type-safe dependency injection to route handlers using FastAPI's lifespan context manager.

## When to Use
- FastAPI applications with async resources (httpx clients, aiohttp sessions)
- Need guaranteed cleanup on shutdown
- Want type-safe dependency injection without complex DI frameworks
- Resources shared across multiple route handlers

## Core Pattern

Use FastAPI's lifespan context manager for resource lifecycle, combined with getter functions for dependency injection.

```python
from contextlib import asynccontextmanager
from fastapi import Depends, FastAPI, HTTPException

_http_client: AsyncClient | None = None
_db_service: DatabaseService | None = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global _http_client, _db_service
    _http_client = AsyncClient(timeout=30.0)
    _db_service = DatabaseService()
    yield
    if _http_client:
        await _http_client.aclose()
    if _db_service:
        await _db_service.close()

app = FastAPI(lifespan=lifespan)

def get_http_client() -> AsyncClient:
    if _http_client is None:
        raise HTTPException(status_code=503, detail="Service not initialized")
    return _http_client

def get_db_service() -> DatabaseService:
    if _db_service is None:
        raise HTTPException(status_code=503, detail="Service not initialized")
    return _db_service

@app.get("/data")
async def get_data(
    client: AsyncClient = Depends(get_http_client),
    db: DatabaseService = Depends(get_db_service),
):
    return await db.fetch_data()
```

## Common Mistakes
- Not checking for None in getter functions (service not initialized)
- Forgetting to cleanup resources in lifespan shutdown
- Using complex DI frameworks when simple Depends suffices
