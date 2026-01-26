# LLM Response Parsing with Application-Level Retry

## Problem
LLM responses are non-deterministic and may return malformed JSON or unexpected formats. Network-level retries (tenacity) don't help when the API succeeds but the content is unparseable.

## Solution
Use tenacity's `retry_if_result` to retry when parse returns None, with exponential backoff.

```python
import structlog
from pydantic import ValidationError
from tenacity import (
    retry,
    retry_if_result,
    stop_after_attempt,
    wait_exponential,
    before_sleep_log,
)

logger = structlog.get_logger()

class LLMAgent:
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=30),
        retry=retry_if_result(lambda x: x is None),
        before_sleep=before_sleep_log(logger, "WARNING"),
        reraise=False,
    )
    async def _fetch_and_parse(self, request: Request) -> Response | None:
        raw = await self.llm_client.chat(
            system_prompt=self.get_system_prompt(),
            user_prompt=self.get_user_prompt(request),
        )
        return self._parse_response(raw)

    async def run(self, request: Request) -> Response:
        response = await self._fetch_and_parse(request)
        if response is None:
            logger.error("all parse attempts failed, using default")
            response = Response(items=[], status="parse_failed")
        return response

    def _parse_response(self, raw: str) -> Response | None:
        json_str = self._extract_json(raw)
        if not json_str:
            return None
        try:
            return Response.model_validate_json(json_str)
        except ValidationError:
            return None

    @staticmethod
    def _extract_json(content: str) -> str | None:
        import re
        code_blocks = re.findall(r"```(?:json)?\s*([\s\S]*?)```", content)
        if code_blocks:
            return code_blocks[-1].strip()
        json_match = re.search(r"\{[\s\S]*\}", content)
        return json_match.group(0) if json_match else None
```

## When to Use
- LLM agents that expect structured JSON output
- Need resilience against LLM response variability
- Want graceful degradation rather than hard failures
- Combine with network-level retries for comprehensive error handling
