---
name: provider-check
description: 测试 OpenClaw 配置中 LLM provider 的可用性。触发方式：/provider_check 或用户问"测试 provider 可用性"、"检查 provider 状态"、"provider 健康检查"。
user-invocable: true
---

# Provider Check

测试 OpenClaw 配置中所有 LLM provider 的连通性和 API 可用性。

## 工作流程

1. 读取配置，提取所有 provider 的 baseUrl、apiKey、api 类型、第一个 model id
2. 对每个 provider 并行执行实际 API 调用测试
3. 汇总结果输出

## 步骤

### 1. 读取 Provider 配置

```bash
node -e "
const cfg = require(process.env.HOME + '/.openclaw/openclaw.json');
for (const [name, p] of Object.entries(cfg.models.providers)) {
  console.log([name, p.baseUrl, p.apiKey, p.api || 'openai-completions', p.models[0].id].join('|'));
}
"
```

输出格式：`name|baseUrl|apiKey|api|modelId`

### 2. API 调用测试

根据 `api` 字段选择请求格式：

**openai-completions：**
```bash
curl -s --connect-timeout 10 -X POST "<baseUrl>/chat/completions" \
  -H "Authorization: Bearer <apiKey>" \
  -H "Content-Type: application/json" \
  -d '{"model":"<modelId>","messages":[{"role":"user","content":"hi"}],"max_tokens":5}'
```

**anthropic-messages：**
```bash
curl -s --connect-timeout 10 -X POST "<baseUrl>/v1/messages" \
  -H "x-api-key: <apiKey>" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{"model":"<modelId>","max_tokens":5,"messages":[{"role":"user","content":"hi"}]}'
```

响应中有 `choices` 或 `content` 字段即为成功；否则提取 `error.message` 作为错误详情。

### 3. 输出结果

```
| Provider | 状态    | 详情              |
|----------|---------|------------------|
| bailian  | ✅ 正常 | glm-5 响应正常    |
| skyapi   | ❌ 异常 | HTTP 500 内部错误 |
```

异常时展示具体错误信息。连接超时（curl 返回空或 000）标记为"连接失败"。
