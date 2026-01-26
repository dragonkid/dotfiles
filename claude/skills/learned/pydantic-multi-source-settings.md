# Pydantic Multi-Source Settings

## Problem
Application configuration needs to come from multiple sources with clear precedence: environment variables → .env file → remote configuration service.

## Solution
Use Pydantic BaseSettings with a model_validator to load fallback values from remote config.

```python
from functools import lru_cache
from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_APOLLO_MAPPING = {
    "remote.api.key": "api_key",
    "remote.timeout": "timeout_seconds",
}

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="APP_",
        env_file=".env",
        case_sensitive=False,
    )

    api_key: str = ""
    timeout_seconds: int = 30

    @model_validator(mode="before")
    @classmethod
    def load_from_remote(cls, data: dict) -> dict:
        client = RemoteConfigClient()
        for remote_key, field in _APOLLO_MAPPING.items():
            if field not in data or not data[field]:
                value = client.get_value(remote_key)
                if value:
                    data[field] = value
        return data

@lru_cache
def get_settings() -> Settings:
    return Settings()
```

## When to Use
- Configuration needed from env vars, .env files, and remote config (Apollo, Consul, etc.)
- Need clear precedence: local env vars override remote defaults
- Want cached singleton settings instance
