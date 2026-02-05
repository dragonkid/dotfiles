---
name: pydantic-basesettings-class-attributes
description: Use when defining constants or mappings in Pydantic BaseSettings or BaseModel subclasses results in "non-annotated attribute" errors requiring ClassVar annotations or module-level constants.
---

# Pydantic BaseSettings Class Attributes Pitfall

## Overview
When defining class attributes in Pydantic BaseSettings classes, Pydantic treats them as model fields and raises an error. Move constants outside the class as module-level private constants or use ClassVar annotation.

## When to Use
- Defining constants in Pydantic BaseSettings or BaseModel subclasses
- Refactoring hardcoded mappings/configs into reusable data structures
- Encountering "non-annotated attribute" errors

## The Problem

Pydantic treats class attributes as model fields:

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
    "remote.timeout": "timeout_seconds",
}

_BOOLEAN_FIELDS = ["debug", "enabled"]

class Settings(BaseSettings):
    grok_api_key: str = ""
    timeout_seconds: int = 30

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

## Common Mistakes
- Defining mappings/constants directly in Pydantic classes without annotation
- Using ClassVar when module-level constants would be cleaner
- Forgetting that Pydantic validates all class attributes by default
