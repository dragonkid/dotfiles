---
name: obsidian-index
description: 手动触发 Obsidian vault 语义索引更新。触发命令：/obsidian_index
user-invocable: true
---

# Obsidian Vault Index

手动触发 vault 增量语义索引。

## Workflow

1. 运行增量索引脚本：
   ```bash
   python3 ~/.openclaw/workspace/scripts/vault_index.py
   ```
2. 等待完成，输出索引结果摘要给用户

## 注意

- 不加 `--reset`，只处理新增/变更文件，跳过未变更文件
- 如需完整重建索引，告知用户运行：`launchctl start com.dk.vault-index` 或手动加 `--reset` 参数
- 日志：`~/.openclaw/workspace/logs/vault-index.log`
