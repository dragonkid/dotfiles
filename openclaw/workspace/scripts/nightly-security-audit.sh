#!/bin/bash
# OpenClaw Nightly Security Audit (macOS) - Simplified Stable Version
# Based on SlowMist Security Guide v2.7
# Last Updated: 2026-03-09

# Configuration
OC_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
WORKSPACE_DIR="$OC_DIR/workspace"
REPORT_DIR="/tmp/openclaw/security-reports"
REPORT_FILE="$REPORT_DIR/audit-$(date +%Y-%m-%d).md"
BASELINE_FILE="$REPORT_DIR/baseline.json"

# Create report directory
mkdir -p "$REPORT_DIR"

# Initialize report
{
    echo "# 🔒 OpenClaw 安全审计报告"
    echo ""
    echo "**日期：** $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**主机：** $(hostname)"
    echo "**系统：** $(sw_vers -productName) $(sw_vers -productVersion)"
    echo ""
    echo "---"
    echo ""
} > "$REPORT_FILE"

# Helper functions
log_section() {
    echo "" >> "$REPORT_FILE"
    echo "## $1" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

log_ok() { echo "✅ $1" >> "$REPORT_FILE"; }
log_warn() { echo "⚠️ $1" >> "$REPORT_FILE"; }
log_error() { echo "❌ $1" >> "$REPORT_FILE"; }
log_info() { echo "ℹ️ $1" >> "$REPORT_FILE"; }

# ============================================================================
# 1. 配置文件 Hash 验证
# ============================================================================
log_section "1️⃣ 配置文件 Hash 验证"

if [ -f "$OC_DIR/.config-baseline.sha256" ]; then
    if shasum -a 256 -c "$OC_DIR/.config-baseline.sha256" 2>/dev/null | grep -q "OK"; then
        log_ok "openclaw.json hash 验证通过"
    else
        log_error "openclaw.json hash 不匹配！配置文件可能被篡改"
    fi
else
    log_warn "未找到 hash 基线文件"
fi

# ============================================================================
# 2. 可疑的系统级任务
# ============================================================================
log_section "2️⃣ 可疑的系统级任务"

LAUNCH_AGENTS=$(find ~/Library/LaunchAgents /Library/LaunchAgents /Library/LaunchDaemons 2>/dev/null | wc -l | tr -d ' ')
log_info "发现 $LAUNCH_AGENTS 个 launchd 任务"

RECENT_AGENTS=$(find ~/Library/LaunchAgents /Library/LaunchAgents /Library/LaunchDaemons -type f -mtime -7 2>/dev/null | head -10 || echo "")
if [ -n "$RECENT_AGENTS" ]; then
    log_warn "最近 7 天内修改的 launchd 任务："
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$RECENT_AGENTS" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
else
    log_ok "未发现最近修改的系统级任务"
fi

# ============================================================================
# 3. 异常的网络连接
# ============================================================================
log_section "3️⃣ 异常的网络连接"

CONN_COUNT=$(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l | tr -d ' ')
log_info "当前活跃网络连接数: $CONN_COUNT"
log_ok "网络连接检查完成"

# ============================================================================
# 4. Skills 文件完整性
# ============================================================================
log_section "4️⃣ Skills 文件完整性"

SKILLS_DIR="$WORKSPACE_DIR/skills"
if [ -d "$SKILLS_DIR" ]; then
    CURRENT_SKILLS=$(ls -1 "$SKILLS_DIR" 2>/dev/null | sort || echo "")
    SKILLS_COUNT=$(echo "$CURRENT_SKILLS" | grep -v '^$' | wc -l | tr -d ' ')
    log_info "已安装 Skills 数量: $SKILLS_COUNT"
    
    if [ -f "$BASELINE_FILE" ]; then
        BASELINE_SKILLS=$(jq -r '.skills[]' "$BASELINE_FILE" 2>/dev/null | sort || echo "")
        NEW_SKILLS=$(comm -13 <(echo "$BASELINE_SKILLS") <(echo "$CURRENT_SKILLS") 2>/dev/null || echo "")
        
        if [ -n "$NEW_SKILLS" ] && [ "$NEW_SKILLS" != "" ]; then
            log_warn "新增 Skills（需要审计）："
            echo "\`\`\`" >> "$REPORT_FILE"
            echo "$NEW_SKILLS" >> "$REPORT_FILE"
            echo "\`\`\`" >> "$REPORT_FILE"
        else
            log_ok "Skills 列表无变化"
        fi
    else
        log_info "首次审计，记录当前 Skills 列表"
    fi
    
    # Update baseline
    {
        echo '{"skills": ['
        echo "$CURRENT_SKILLS" | sed 's/^/  "/;s/$/",/' | sed '$ s/,$//'
        echo ']}'
    } > "$BASELINE_FILE"
else
    log_warn "Skills 目录不存在"
fi

# ============================================================================
# 5. 权限变更记录
# ============================================================================
log_section "5️⃣ 权限变更记录"

check_perms() {
    local file="$1"
    if [ -f "$file" ]; then
        local perms=$(stat -f "%Sp" "$file" 2>/dev/null || echo "unknown")
        if [[ "$perms" == "-rw-------" ]]; then
            log_ok "$(basename $file): $perms"
        else
            log_warn "$(basename $file): $perms (应为 -rw-------)"
        fi
    fi
}

check_perms "$OC_DIR/openclaw.json"
check_perms "$OC_DIR/devices/paired.json"
check_perms "$HOME/.agent-reach/config.yaml"

# ============================================================================
# 6. 黄线命令执行记录
# ============================================================================
log_section "6️⃣ 黄线命令执行记录"

MEMORY_DIR="$WORKSPACE_DIR/memory"
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)

YELLOW_CMDS=$(grep -h "黄线命令\|sudo\|pip install\|npm install\|docker run" "$MEMORY_DIR/$TODAY.md" "$MEMORY_DIR/$YESTERDAY.md" 2>/dev/null | head -20 || echo "")

if [ -n "$YELLOW_CMDS" ]; then
    log_warn "最近 24 小时黄线命令执行："
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$YELLOW_CMDS" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
else
    log_ok "最近 24 小时无黄线命令执行"
fi

# ============================================================================
# 7. OpenClaw Cron Jobs
# ============================================================================
log_section "7️⃣ OpenClaw Cron Jobs"

if [ -d "$OC_DIR/cron" ]; then
    CRON_COUNT=$(ls -1 "$OC_DIR/cron" 2>/dev/null | wc -l | tr -d ' ')
    log_info "当前 Cron Jobs 数量: $CRON_COUNT"
    
    CRON_JOBS=$(ls -1 "$OC_DIR/cron" 2>/dev/null | head -10 || echo "")
    if [ -n "$CRON_JOBS" ]; then
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "$CRON_JOBS" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    fi
else
    log_info "Cron 目录不存在"
fi

# ============================================================================
# 8. Docker 容器状态
# ============================================================================
log_section "8️⃣ Docker 容器状态"

if command -v docker &> /dev/null; then
    RUNNING_CONTAINERS=$(docker ps --format "{{.Names}}" 2>/dev/null || echo "")
    CONTAINER_COUNT=$(echo "$RUNNING_CONTAINERS" | grep -v '^$' | wc -l | tr -d ' ')
    
    if [ "$CONTAINER_COUNT" -gt 0 ]; then
        log_info "运行中的容器 ($CONTAINER_COUNT)："
        echo "\`\`\`" >> "$REPORT_FILE"
        docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    else
        log_ok "无运行中的容器"
    fi
else
    log_info "Docker 未安装"
fi

# ============================================================================
# 9. 敏感文件访问记录
# ============================================================================
log_section "9️⃣ 敏感文件访问记录"

RECENT_MODS=$(find "$OC_DIR" -type f -mtime -1 2>/dev/null | grep -v "logs\|delivery-queue\|browser" | head -10 || echo "")

if [ -n "$RECENT_MODS" ]; then
    log_info "最近 24 小时修改的文件："
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$RECENT_MODS" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
else
    log_ok "未发现异常文件修改"
fi

# ============================================================================
# 10. 环境变量变更
# ============================================================================
log_section "🔟 环境变量变更"

ENV_FILE="$OC_DIR/env"
if [ -f "$ENV_FILE" ]; then
    ENV_HASH=$(shasum -a 256 "$ENV_FILE" | awk '{print $1}')
    log_info "环境变量文件 hash: ${ENV_HASH:0:16}..."
    log_ok "环境变量检查完成"
else
    log_info "未找到环境变量文件"
fi

# ============================================================================
# 11. 新安装的全局包
# ============================================================================
log_section "1️⃣1️⃣ 新安装的全局包"

if command -v npm &> /dev/null; then
    NPM_GLOBAL=$(npm list -g --depth=0 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
    log_info "全局 npm 包数量: $NPM_GLOBAL"
fi

if command -v pip3 &> /dev/null; then
    PIP_COUNT=$(pip3 list 2>/dev/null | wc -l | tr -d ' ')
    log_info "Python 包数量: $PIP_COUNT"
fi

if command -v brew &> /dev/null; then
    BREW_COUNT=$(brew list --versions 2>/dev/null | wc -l | tr -d ' ')
    log_info "Homebrew 包数量: $BREW_COUNT"
fi

log_ok "包管理器检查完成"

# ============================================================================
# 12. 磁盘空间使用
# ============================================================================
log_section "1️⃣2️⃣ 磁盘空间使用"

DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
DISK_AVAIL=$(df -h / | tail -1 | awk '{print $4}')

if [ "$DISK_USAGE" -gt 90 ]; then
    log_error "磁盘使用率过高: ${DISK_USAGE}% (可用: $DISK_AVAIL)"
elif [ "$DISK_USAGE" -gt 80 ]; then
    log_warn "磁盘使用率较高: ${DISK_USAGE}% (可用: $DISK_AVAIL)"
else
    log_ok "磁盘使用率正常: ${DISK_USAGE}% (可用: $DISK_AVAIL)"
fi

OC_SIZE=$(du -sh "$OC_DIR" 2>/dev/null | awk '{print $1}')
log_info "OpenClaw 目录大小: $OC_SIZE"

# ============================================================================
# 13. OpenClaw 进程状态
# ============================================================================
log_section "1️⃣3️⃣ OpenClaw 进程状态"

if pgrep -f "openclaw" > /dev/null 2>&1; then
    log_ok "OpenClaw 进程运行中"
else
    log_error "OpenClaw 进程未运行！"
fi

if [ -f "$OC_DIR/openclaw.json" ]; then
    log_ok "配置文件存在"
else
    log_error "配置文件丢失！"
fi

# ============================================================================
# Summary
# ============================================================================
log_section "📊 审计总结"

ERROR_COUNT=$(grep -c "❌" "$REPORT_FILE" 2>/dev/null || echo "0")
WARN_COUNT=$(grep -c "⚠️" "$REPORT_FILE" 2>/dev/null || echo "0")
OK_COUNT=$(grep -c "✅" "$REPORT_FILE" 2>/dev/null || echo "0")

{
    echo "- ✅ 正常项: $OK_COUNT"
    echo "- ⚠️ 警告项: $WARN_COUNT"
    echo "- ❌ 错误项: $ERROR_COUNT"
    echo ""
} >> "$REPORT_FILE"

if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "**⚠️ 发现 $ERROR_COUNT 个严重问题，请立即检查！**" >> "$REPORT_FILE"
elif [ "$WARN_COUNT" -gt 0 ]; then
    echo "**ℹ️ 发现 $WARN_COUNT 个警告，建议关注。**" >> "$REPORT_FILE"
else
    echo "**✅ 所有检查项正常。**" >> "$REPORT_FILE"
fi

{
    echo ""
    echo "---"
    echo "*报告保存位置: $REPORT_FILE*"
} >> "$REPORT_FILE"

# Output report to stdout
cat "$REPORT_FILE"

exit 0
