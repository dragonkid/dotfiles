# FastAPI Lifespan + Dependency Injection

## Problem
Need to manage async resource lifecycle (HTTP clients, database connections) with clean initialization and shutdown, while providing type-safe dependency injection to route handlers.

## Solution
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

## When to Use
- FastAPI applications with async resources (httpx clients, aiohttp sessions)
- Need guaranteed cleanup on shutdown
- Want type-safe dependency injection without complex DI frameworks
- Resources shared across multiple route handlers
