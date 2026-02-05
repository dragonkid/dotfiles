---
name: dto-factory-method
description: Use when consuming external APIs with non-standard field names, need default value handling for missing fields, or want to decouple API response structure from domain model with clean conversion patterns.
---

# DTO with Factory Method Pattern

## Overview
External API responses have inconsistent field names, nested structures, and optional fields. This pattern provides clean conversion to domain models with default handling using Pydantic models with factory methods.

## When to Use
- Consuming external APIs with non-standard field names
- Need default value handling for missing/optional fields
- Want to decouple API response structure from domain model
- Need multiple output formats (prompt text, JSON, display strings)

## Core Pattern

Use Pydantic models with `from_api_response` class method for conversion and optional `to_*` methods for output formatting.

```python
from pydantic import BaseModel

class TokenInfo(BaseModel):
    symbol: str
    name: str
    price: float
    market_cap: float | None = None

    @classmethod
    def from_api_response(cls, response: dict) -> "TokenInfo":
        data = response.get("data", response)
        return cls(
            symbol=data.get("sym", "N/A"),
            name=data.get("n", data.get("name", "Unknown")),
            price=float(data.get("p", 0)),
            market_cap=data.get("mc"),
        )

    def to_prompt_lines(self, fields: list[str] | None = None) -> list[str]:
        formatters = {
            "symbol": lambda: f"- Symbol: {self.symbol}",
            "name": lambda: f"- Name: {self.name}",
            "price": lambda: f"- Price: ${self.price:,.2f}",
            "market_cap": lambda: f"- Market Cap: ${self.market_cap:,.0f}" if self.market_cap else None,
        }
        fields = fields or list(formatters.keys())
        lines = []
        for field in fields:
            if field in formatters:
                line = formatters[field]()
                if line:
                    lines.append(line)
        return lines

# Usage:
api_response = {"data": {"sym": "BTC", "n": "Bitcoin", "p": "67000.50"}}
token = TokenInfo.from_api_response(api_response)
prompt_text = "\n".join(token.to_prompt_lines(["symbol", "price"]))
```

## Common Mistakes
- Not handling nested response structures (check `response.get("data", response)`)
- Forgetting to convert types (e.g., `float(data.get("p", 0))`)
- Over-complicating with unnecessary transformations
