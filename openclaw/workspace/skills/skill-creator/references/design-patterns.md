# Design Patterns for Skills

## Progressive Disclosure

Skills 使用三级加载：
1. **Metadata**（name + description）— 始终在 context 中
2. **SKILL.md 正文** — skill 触发后加载
3. **references/ 文件** — Claude 按需读取

**原则：** SKILL.md 只放核心流程，详细内容放 references/。

## Pattern 1: 高层指引 + references

```markdown
## 高级功能

- **表单填写**：见 [FORMS.md](FORMS.md)
- **API 参考**：见 [REFERENCE.md](REFERENCE.md)
```

## Pattern 2: 按领域拆分

```
bigquery-skill/
├── SKILL.md
└── references/
    ├── finance.md
    ├── sales.md
    └── product.md
```

用户问销售数据时，只读 sales.md。

## Pattern 3: 按变体拆分

```
cloud-deploy/
├── SKILL.md
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

## Pattern 4: 条件加载

```markdown
## 编辑文档

简单编辑直接修改 XML。

**追踪修改**：见 [REDLINING.md](REDLINING.md)
**OOXML 细节**：见 [OOXML.md](OOXML.md)
```

## 自由度设置

| 场景 | 自由度 | 形式 |
|------|--------|------|
| 多种方案均可 | 高 | 文字说明 |
| 有偏好模式但可变 | 中 | 伪代码/带参数脚本 |
| 操作脆弱、顺序关键 | 低 | 具体脚本 |

## references 文件规范

- 超过 100 行的文件，顶部加目录
- 只从 SKILL.md 直接引用，不要嵌套引用
- 文件名语义化，如 `discord-api.md`、`schema.md`
