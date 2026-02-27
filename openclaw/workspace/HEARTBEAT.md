# Heartbeat checklist

# Add tasks below when you want the agent to check something periodically.

## 清理 .vault-attachments/
清理 `~/.openclaw/workspace/.vault-staging/` 中超过 24 小时的文件：
```bash
find ~/.openclaw/workspace/.vault-staging/ -type f -mtime +1 -delete
```
