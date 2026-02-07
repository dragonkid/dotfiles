# 浏览器配置总结

*记录日期：2026-02-07*

---

## 配置方案

根据 OpenClaw 官方文档推荐，采用 **`openclaw` profile（独立管理浏览器）** 作为主要方案。

### 当前配置

```json5
{
  browser: {
    enabled: true,
    defaultProfile: "openclaw",    // 使用独立管理的浏览器
    headless: false,               // 保持有界面（方便登录）
    color: "#FF4500",              // 橙色标识
    profiles: {
      openclaw: { 
        cdpPort: 18800, 
        color: "#FF4500" 
      }
    }
  }
}
```

---

## 为什么选择 `openclaw` Profile

### 官方推荐理由
1. ✅ **完全隔离** - 独立的浏览器配置文件，不影响日常浏览器
2. ✅ **橙色 UI 标识** - 一眼看出是 AI 控制的浏览器
3. ✅ **确定性控制** - 标签页、点击、输入等操作更可靠
4. ✅ **手动登录** - 可以手动登录网站（避免自动登录触发反爬）
5. ✅ **安全** - 与个人浏览器完全分离

### 与其他方案对比

| 特性 | `openclaw` Profile (当前) | `chrome` Profile (Extension Relay) |
|------|---------------------------|-----------------------------------|
| 隔离性 | ✅ 完全独立 | ❌ 使用你的浏览器 |
| 登录状态 | ✅ 手动登录一次，持久保存 | ✅ 使用现有登录 |
| 自动化可靠性 | ✅ 高 | ⚠️ 需要手动激活标签页 |
| 资源占用 | ⚠️ 额外浏览器进程 | ✅ 复用现有浏览器 |
| 安全性 | ✅ 高（隔离） | ⚠️ 可能影响你的浏览器 |

---

## 测试结果（2026-02-07）

### 测试场景
访问 Twitter/X 长文并提取内容

### 测试步骤
1. 启动 `openclaw` 浏览器
2. 打开 Twitter/X 链接：https://x.com/affaanmustafa/status/2014040193557471352
3. 等待页面加载（3秒）
4. 抓取页面内容（snapshot）
5. 提取并总结文章内容

### 测试结果
✅ **成功** - 完整抓取了长文内容（约15000+ tokens）
✅ **性能良好** - 页面加载和内容提取流畅
✅ **内容准确** - 成功识别文章结构和关键信息

### 遇到的问题
⚠️ **初次加载慢** - 页面显示 "Loading…"，需要等待3秒
✅ **解决方案** - 添加 `sleep 3` 后再抓取

---

## 使用指南

### 日常使用流程

#### 1. 启动浏览器
```bash
# CLI 方式
openclaw browser --browser-profile openclaw start

# 或通过 AI 命令
browser.start(profile="openclaw")
```

#### 2. 打开网页
```bash
# CLI 方式
openclaw browser --browser-profile openclaw open https://example.com

# 或通过 AI 命令
browser.open(profile="openclaw", targetUrl="https://example.com")
```

#### 3. 抓取内容
```bash
# 获取页面快照
browser.snapshot(profile="openclaw")

# 截图
browser.screenshot(profile="openclaw")
```

#### 4. 关闭浏览器
```bash
# CLI 方式
openclaw browser --browser-profile openclaw stop

# 或通过 AI 命令
browser.stop(profile="openclaw")
```

---

## 最佳实践

### 1. 任务完成后关闭浏览器
- **原因：** 节省系统资源（内存、CPU）
- **规则：** 每次使用浏览器完成任务后，主动关闭

### 2. 手动登录重要网站
- **推荐网站：** Twitter/X, GitHub, Gmail
- **操作：** 启动浏览器后，手动访问并登录，浏览器会保持会话
- **安全：** 不要让 AI 自动登录（避免触发反爬虫）

### 3. 等待页面加载
- **动态内容：** 使用 `sleep 2-5` 等待 JavaScript 渲染
- **慢速网站：** 增加等待时间

### 4. 选择合适的操作
- **简单页面：** 用 `web_fetch`（不启动浏览器）
- **需要 JS 渲染：** 用 `browser.snapshot`
- **需要交互：** 用 `browser.act`（点击、输入等）

---

## 常见场景

### 场景 1：抓取需要登录的网站
```
1. 启动 openclaw 浏览器
2. 手动访问并登录（仅首次）
3. AI 后续自动访问，利用已登录状态
```

### 场景 2：研究技术文档
```
1. 启动浏览器
2. 打开文档页面
3. 抓取并总结内容
4. 关闭浏览器
```

### 场景 3：监控网站变化
```
1. 定期启动浏览器
2. 访问目标页面
3. 提取关键信息
4. 与上次结果对比
5. 关闭浏览器
```

---

## 技术细节

### 配置文件位置
- **Gateway 配置：** `~/.openclaw/openclaw.json`
- **浏览器数据目录：** `~/.openclaw/browser/openclaw/user-data`
- **CDP 端口：** 18800（Chrome DevTools Protocol）

### 文档参考
- **官方文档：** `/usr/local/lib/node_modules/openclaw/docs/tools/browser.md`
- **登录指南：** `/usr/local/lib/node_modules/openclaw/docs/tools/browser-login.md`

### 关键配置项说明
- `enabled`: 是否启用浏览器控制
- `defaultProfile`: 默认使用的 profile（`openclaw` 或 `chrome`）
- `headless`: 是否无界面运行（false = 有界面）
- `color`: 浏览器 UI 标识颜色
- `cdpPort`: Chrome DevTools Protocol 端口

---

## 故障排查

### 问题 1：浏览器启动失败
**检查：**
```bash
# 检查 Chrome 是否安装
ls "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# 查看错误日志
openclaw logs --follow
```

### 问题 2：页面内容为空
**解决：**
- 增加等待时间（`sleep 5`）
- 检查是否需要登录
- 尝试刷新页面

### 问题 3：浏览器未关闭
**手动关闭：**
```bash
openclaw browser --browser-profile openclaw stop
```

---

## 未来优化方向

### 1. 自动化常见任务
- 创建 skill 封装浏览器操作
- 例如：`/browse <url>` 自动启动→访问→抓取→关闭

### 2. 批量操作
- 同时打开多个标签页
- 并行抓取多个页面

### 3. 与其他工具集成
- 结合 `web_search` 先搜索，再用浏览器深度抓取
- 集成 Obsidian，自动保存研究结果

---

## 更新日志

### 2026-02-07
- ✅ 完成初始配置（`openclaw` profile）
- ✅ 测试 Twitter/X 长文抓取（成功）
- ✅ 确认"任务完成后关闭浏览器"规则
- ✅ 创建本文档

---

*配置和测试由 AI 助手完成。如有问题或改进建议，请更新此文档。*
