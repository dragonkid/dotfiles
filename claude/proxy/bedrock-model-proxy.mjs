#!/usr/bin/env node
// Reverse proxy that rewrites Claude model names to Bedrock/LiteLLM format.
//
// Claude Code internally resolves "haiku" → "claude-haiku-4-5-20251001" etc.
// LiteLLM proxy expects "bedrock-claude-haiku-4-5" etc.
// This proxy sits in between and rewrites the model field.
//
// Usage:
//   node bedrock-model-proxy.mjs [--port 8099] [--upstream https://litellm-prod.toolsfdg.net]
//
// Then set: ANTHROPIC_BASE_URL=http://localhost:8099

import { createServer } from "node:http";
import { request as httpsRequest } from "node:https";
import { request as httpRequest } from "node:http";
import { URL } from "node:url";

const args = process.argv.slice(2);
function getArg(name, fallback) {
  const i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : fallback;
}

const PORT = parseInt(getArg("--port", "8099"), 10);
const UPSTREAM = getArg("--upstream", process.env.BEDROCK_UPSTREAM_URL || "https://litellm-prod.toolsfdg.net");
const upstreamUrl = new URL(UPSTREAM);
const doRequest = upstreamUrl.protocol === "https:" ? httpsRequest : httpRequest;

// All non-bedrock Claude models get rewritten to the single available model.
// Only bedrock-claude-4-6-opus is available on the LiteLLM proxy.
const TARGET_MODEL = process.env.BEDROCK_TARGET_MODEL || "bedrock-claude-4-6-opus[1m]";

function rewriteModel(model) {
  if (!model) return model;
  if (model.startsWith("bedrock-")) return model;
  if (model.startsWith("claude-")) return TARGET_MODEL;
  return model;
}

const server = createServer((req, res) => {
  const chunks = [];

  req.on("data", (chunk) => chunks.push(chunk));
  req.on("end", () => {
    const rawBody = Buffer.concat(chunks);
    let body = rawBody;
    let originalModel = null;
    let newModel = null;

    // Rewrite model in JSON body
    if (rawBody.length > 0) {
      try {
        const json = JSON.parse(rawBody.toString());
        if (json.model) {
          originalModel = json.model;
          newModel = rewriteModel(json.model);
          json.model = newModel;
          body = Buffer.from(JSON.stringify(json));
        }
      } catch {
        // Not JSON or parse error — forward as-is
      }
    }

    if (originalModel && originalModel !== newModel) {
      process.stderr.write(`[proxy] ${originalModel} → ${newModel}\n`);
    }

    // Build upstream request headers
    const headers = { ...req.headers };
    headers.host = upstreamUrl.host;
    if (body.length !== rawBody.length) {
      headers["content-length"] = body.length;
    }

    const proxyReq = doRequest(
      {
        hostname: upstreamUrl.hostname,
        port: upstreamUrl.port || (upstreamUrl.protocol === "https:" ? 443 : 80),
        path: req.url,
        method: req.method,
        headers,
      },
      (proxyRes) => {
        res.writeHead(proxyRes.statusCode, proxyRes.headers);
        proxyRes.pipe(res, { end: true });
      }
    );

    proxyReq.on("error", (err) => {
      process.stderr.write(`[proxy] upstream error: ${err.message}\n`);
      if (!res.headersSent) {
        res.writeHead(502, { "content-type": "application/json" });
        res.end(JSON.stringify({ error: { message: `Proxy upstream error: ${err.message}` } }));
      }
    });

    proxyReq.write(body);
    proxyReq.end();
  });
});

server.listen(PORT, "127.0.0.1", () => {
  process.stderr.write(`[proxy] Bedrock model proxy listening on http://127.0.0.1:${PORT}\n`);
  process.stderr.write(`[proxy] Upstream: ${UPSTREAM}\n`);
});
