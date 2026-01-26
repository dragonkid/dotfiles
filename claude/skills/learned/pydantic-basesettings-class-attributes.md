# Pydantic BaseSettings Class Attributes Pitfall

**Extracted:** 2026-01-26
**Context:** Defining constants or mappings in Pydantic BaseSettings subclasses

## Problem

When defining class attributes in Pydantic BaseSettings classes, Pydantic treats them as model fields and raises an error:

```
PydanticUserError: A non-annotated attribute was detected: `MAPPING = {...}`.
All model fields require a type annotation; if `MAPPING` is not meant to be a field,
you may be able to resolve this error by annotating it as a `ClassVar`
```

## Solution

**Recommended:** Move constants outside the class as module-level private constants

```python
# Correct approach
_APOLLO_MAPPING = {
    "grok.api.key": "grok_api_key",
    ...
}

_BOOLEAN_FIELDS = ["debug", "enabled"]

class Settings(BaseSettings):
    grok_api_key: str = ""

    @model_validator(mode="before")
    @classmethod
    def load_from_apollo(cls, data):
        for apollo_key, field in _APOLLO_MAPPING.items():
            ...
```

**Alternative:** Use ClassVar type annotation (works but less clean)

```python
from typing import ClassVar

class Settings(BaseSettings):
    MAPPING: ClassVar[dict[str, str]] = {...}
```

## When to Use

- Defining constants in Pydantic BaseSettings or BaseModel subclasses
- Refactoring hardcoded mappings/configs into reusable data structures
- Encountering "non-annotated attribute" errors
