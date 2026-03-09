#!/bin/bash
# OpenClaw Nightly Security Audit (macOS) - Complete Version
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
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "预期: $(cat $OC_DIR/.config-baseline.sha256)" >> "$REPORT_FILE"
        echo "实际: $(shasum -a 256 $OC_DIR/openclaw.json)" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    fi
else
    log_warn "未找到 hash 基线文件，无法验证配置完整性"
fi

# Check paired.json if exists
if [ -f "$OC_DIR/devices/paired.json" ]; then
    PAIRED_SIZE=$(stat -f%z "$OC_DIR/devices/paired.json" 2>/dev/null || echo "0")
    if [ "$PAIRED_SIZE" -gt 0 ]; then
        log_ok "paired.json 存在且非空"
    else
        log_warn "paired.json 为空"
    fi
fi

# ============================================================================
# 2. 可疑的系统级任务
# ============================================================================
log_section "2️⃣ 可疑的系统级任务"

# Count all launchd tasks
LAUNCH_AGENTS=$(find ~/Library/LaunchAgents /Library/LaunchAgents /Library/LaunchDaemons 2>/dev/null | wc -l | tr -d ' ')
log_info "发现 $LAUNCH_AGENTS 个 launchd 任务"

# List recently modified launch agents (last 7 days)
RECENT_AGENTS=$(find ~/Library/LaunchAgents /Library/LaunchAgents /Library/LaunchDaemons -type f -mtime -7 2>/dev/null || echo "")
if [ -n "$RECENT_AGENTS" ]; then
    log_warn "最近 7 天内修改的 launchd 任务："
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$RECENT_AGENTS" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
else
    log_ok "未发现最近修改的系统级任务"
fi

# Check for suspicious patterns in launch agents
SUSPICIOUS_PATTERNS=$(grep -r "curl\|wget\|bash -c\|eval" ~/Library/LaunchAgents/*.plist 2>/dev/null | head -5 || echo "")
if [ -n "$SUSPICIOUS_PATTERNS" ]; then
    log_warn "发现可疑的 launchd 任务模式："
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$SUSPICIOUS_PATTERNS" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
fi

# ============================================================================
# 3. 异常的网络连接
# ============================================================================
log_section "3️⃣ 异常的网络连接"

# Use netstat instead of lsof for better compatibility
ESTABLISHED_CONNS=$(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l | tr -d ' ')
log_info "当前活跃网络连接数: $ESTABLISHED_CONNS"

# Check for connections on unusual ports
UNUSUAL_PORTS=$(netstat -an 2>/dev/null | grep ESTABLISHED | awk '{print $4}' | grep -v ":80\|:443\|:22\|:53" | head -10 || echo "")
if [ -n "$UNUSUAL_PORTS" ]; then
    log_info "非标准端口连接："
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$UNUSUAL_PORTS" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
fi

# Check for listening ports
LISTENING_PORTS=$(netstat -an 2>/dev/null | grep LISTEN | awk '{print $4}' | sort -u | head -20 || echo "")
if [ -n "$LISTENING_PORTS" ]; then
    log_info "监听端口："
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$LISTENING_PORTS" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
fi

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
    
    # List all skills with their modification times
    echo "\`\`\`" >> "$REPORT_FILE"
    ls -lt "$SKILLS_DIR" 2>/dev/null | head -20 >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    
    # Compare with baseline
    if [ -f "$BASELINE_FILE" ]; then
        BASELINE_SKILLS=$(jq -r '.skills[]' "$BASELINE_FILE" 2>/dev/null | sort || echo "")
        
        # Check for new skills
        NEW_SKILLS=$(comm -13 <(echo "$BASELINE_SKILLS") <(echo "$CURRENT_SKILLS") 2>/dev/null || echo "")
        if [ -n "$NEW_SKILLS" ] && [ "$NEW_SKILLS" != "" ]; then
            log_warn "新增 Skills（需要审计）："
            echo "\`\`\`" >> "$REPORT_FILE"
            echo "$NEW_SKILLS" >> "$REPORT_FILE"
            echo "\`\`\`" >> "$REPORT_FILE"
        fi
        
        # Check for removed skills
        REMOVED_SKILLS=$(comm -23 <(echo "$BASELINE_SKILLS") <(echo "$CURRENT_SKILLS") 2>/dev/null || echo "")
        if [ -n "$REMOVED_SKILLS" ] && [ "$REMOVED_SKILLS" != "" ]; then
            log_info "已删除 Skills："
            echo "\`\`\`" >> "$REPORT_FILE"
            echo "$REMOVED_SKILLS" >> "$REPORT_FILE"
            echo "\`\`\`" >> "$REPORT_FILE"
        fi
        
        if [ -z "$NEW_SKILLS" ] && [ -z "$REMOVED_SKILLS" ]; then
            log_ok "Skills 列表无变化"
        fi
    else
        log_info "首次审计，记录当前 Skills 列表"
    fi
    
    # Check for suspicious files in skills
    SUSPICIOUS_FILES=$(find "$SKILLS_DIR" -type f \( -name "*.sh" -o -name "install.sh" \) -mtime -7 2>/dev/null || echo "")
    if [ -n "$SUSPICIOUS_FILES" ]; then
        log_warn "最近 7 天修改的 Skill 脚本："
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "$SUSPICIOUS_FILES" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    fi
    
    # Update baseline
    {
        echo '{"skills": ['
        echo "$CURRENT_SKILLS" | sed 's/^/  "/;s/$/",/' | sed '$ s/,$//'
        echo '],'
        echo "\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
        echo '}'
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
    local expected="$2"
    if [ -f "$file" ]; then
        local perms=$(stat -f "%Sp" "$file" 2>/dev/null || echo "unknown")
        local owner=$(stat -f "%Su:%Sg" "$file" 2>/dev/null || echo "unknown")
        if [[ "$perms" == "$expected" ]]; then
            log_ok "$(basename $file): $perms (owner: $owner)"
        else
            log_warn "$(basename $file): $perms (应为 $expected, owner: $owner)"
        fi
    else
        log_info "$(basename $file): 文件不存在"
    fi
}

# Check critical files
check_perms "$OC_DIR/openclaw.json" "-rw-------"
check_perms "$OC_DIR/devices/paired.json" "-rw-------"
check_perms "$HOME/.agent-reach/config.yaml" "-rw-------"

# Check for world-readable sensitive files
WORLD_READABLE=$(find "$OC_DIR" -type f -perm -004 2>/dev/null | grep -E "(json|yaml|key|token)" | head -10 || echo "")
if [ -n "$WORLD_READABLE" ]; then
    log_error "发现 world-readable 的敏感文件："
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$WORLD_READABLE" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
fi

# Check for files with unusual permissions
UNUSUAL_PERMS=$(find "$OC_DIR" -type f \( -perm -002 -o -perm -020 \) 2>/dev/null | head -10 || echo "")
if [ -n "$UNUSUAL_PERMS" ]; then
    log_warn "发现权限异常的文件（group/other writable）："
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$UNUSUAL_PERMS" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
fi

# ============================================================================
# 6. 黄线命令执行记录
# ============================================================================
log_section "6️⃣ 黄线命令执行记录"

MEMORY_DIR="$WORKSPACE_DIR/memory"
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)

# Search for yellow-line commands in memory files
YELLOW_PATTERNS="黄线命令|sudo|pip install|npm install|brew install|docker run|launchctl|pfctl|chflags"
YELLOW_CMDS=$(grep -hE "$YELLOW_PATTERNS" "$MEMORY_DIR/$TODAY.md" "$MEMORY_DIR/$YESTERDAY.md" 2>/dev/null | head -20 || echo "")

if [ -n "$YELLOW_CMDS" ]; then
    log_warn "最近 24 小时黄线命令执行："
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$YELLOW_CMDS" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
else
    log_ok "最近 24 小时无黄线命令执行"
fi

# Check shell history for suspicious commands (last 100 commands)
if [ -f "$HOME/.zsh_history" ]; then
    SUSPICIOUS_HISTORY=$(tail -100 "$HOME/.zsh_history" 2>/dev/null | grep -E "curl.*sh|wget.*bash|base64.*bash|eval|nc -e" | head -5 || echo "")
    if [ -n "$SUSPICIOUS_HISTORY" ]; then
        log_error "发现可疑的 shell 历史命令："
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "$SUSPICIOUS_HISTORY" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    fi
fi

# ============================================================================
# 7. OpenClaw Cron Jobs
# ============================================================================
log_section "7️⃣ OpenClaw Cron Jobs"

if [ -d "$OC_DIR/cron" ]; then
    CRON_COUNT=$(ls -1 "$OC_DIR/cron" 2>/dev/null | wc -l | tr -d ' ')
    log_info "当前 Cron Jobs 数量: $CRON_COUNT"
    
    CRON_JOBS=$(ls -1 "$OC_DIR/cron" 2>/dev/null || echo "")
    if [ -n "$CRON_JOBS" ]; then
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "$CRON_JOBS" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    fi
    
    # Check for recently modified cron jobs
    RECENT_CRON=$(find "$OC_DIR/cron" -type f -mtime -7 2>/dev/null || echo "")
    if [ -n "$RECENT_CRON" ]; then
        log_info "最近 7 天修改的 Cron Jobs："
        echo "\`\`\`" >> "$REPORT_FILE"
        ls -lt "$OC_DIR/cron" 2>/dev/null | head -10 >> "$REPORT_FILE"
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
    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        RUNNING_CONTAINERS=$(docker ps --format "{{.Names}}" 2>/dev/null || echo "")
        CONTAINER_COUNT=$(echo "$RUNNING_CONTAINERS" | grep -v '^$' | wc -l | tr -d ' ')
        
        if [ "$CONTAINER_COUNT" -gt 0 ]; then
            log_info "运行中的容器 ($CONTAINER_COUNT)："
            echo "\`\`\`" >> "$REPORT_FILE"
            docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null >> "$REPORT_FILE"
            echo "\`\`\`" >> "$REPORT_FILE"
            
            # Check for containers with privileged mode
            PRIVILEGED=$(docker ps -q 2>/dev/null | xargs -I {} docker inspect {} --format '{{.Name}}: {{.HostConfig.Privileged}}' 2>/dev/null | grep true || echo "")
            if [ -n "$PRIVILEGED" ]; then
                log_warn "发现特权模式容器："
                echo "\`\`\`" >> "$REPORT_FILE"
                echo "$PRIVILEGED" >> "$REPORT_FILE"
                echo "\`\`\`" >> "$REPORT_FILE"
            fi
            
            # Check for containers with host network
            HOST_NETWORK=$(docker ps -q 2>/dev/null | xargs -I {} docker inspect {} --format '{{.Name}}: {{.HostConfig.NetworkMode}}' 2>/dev/null | grep host || echo "")
            if [ -n "$HOST_NETWORK" ]; then
                log_info "使用 host 网络的容器："
                echo "\`\`\`" >> "$REPORT_FILE"
                echo "$HOST_NETWORK" >> "$REPORT_FILE"
                echo "\`\`\`" >> "$REPORT_FILE"
            fi
        else
            log_ok "无运行中的容器"
        fi
        
        # Check for dangling images
        DANGLING=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l | tr -d ' ')
        if [ "$DANGLING" -gt 0 ]; then
            log_info "发现 $DANGLING 个悬空镜像（可清理）"
        fi
    else
        log_info "Docker daemon 未运行"
    fi
else
    log_info "Docker 未安装"
fi

# ============================================================================
# 9. 敏感文件访问记录
# ============================================================================
log_section "9️⃣ 敏感文件访问记录"

# Check recently modified files in OpenClaw directory (last 24 hours)
RECENT_MODS=$(find "$OC_DIR" -type f -mtime -1 2>/dev/null | grep -v "logs\|delivery-queue\|browser\|sessions" | head -20 || echo "")

if [ -n "$RECENT_MODS" ]; then
    log_info "最近 24 小时修改的文件："
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$RECENT_MODS" | while read file; do
        echo "$(stat -f "%Sm %N" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null)"
    done >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
else
    log_ok "未发现异常文件修改"
fi

# Check for new files in workspace
NEW_WORKSPACE_FILES=$(find "$WORKSPACE_DIR" -type f -mtime -1 2>/dev/null | grep -v "memory\|.vault_chroma" | head -10 || echo "")
if [ -n "$NEW_WORKSPACE_FILES" ]; then
    log_info "工作区新增文件："
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$NEW_WORKSPACE_FILES" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
fi

# ============================================================================
# 10. 环境变量变更
# ============================================================================
log_section "🔟 环境变量变更"

ENV_FILE="$OC_DIR/env"
if [ -f "$ENV_FILE" ]; then
    ENV_HASH=$(shasum -a 256 "$ENV_FILE" 2>/dev/null | awk '{print $1}')
    log_info "环境变量文件 hash: ${ENV_HASH:0:16}..."
    
    # Check for sensitive environment variables
    SENSITIVE_COUNT=$(grep -cE "(TOKEN|KEY|SECRET|PASSWORD|API)" "$ENV_FILE" 2>/dev/null || echo "0")
    log_info "环境变量文件包含 $SENSITIVE_COUNT 个敏感变量"
    
    log_ok "环境变量检查完成"
else
    log_info "未找到环境变量文件"
fi

# Check current process environment for leaks
CURRENT_ENV_SENSITIVE=$(env 2>/dev/null | grep -cE "(TOKEN|KEY|SECRET|PASSWORD|API)" || echo "0")
if [ "$CURRENT_ENV_SENSITIVE" -gt 0 ]; then
    log_warn "当前环境中发现 $CURRENT_ENV_SENSITIVE 个敏感变量"
fi

# ============================================================================
# 11. 新安装的全局包
# ============================================================================
log_section "1️⃣1️⃣ 新安装的全局包"

# Check npm global packages
if command -v npm &> /dev/null; then
    NPM_GLOBAL=$(npm list -g --depth=0 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
    log_info "全局 npm 包数量: $NPM_GLOBAL"
    
    # List recently installed packages (if npm supports it)
    RECENT_NPM=$(npm list -g --depth=0 2>/dev/null | tail -n +2 | head -10 || echo "")
    if [ -n "$RECENT_NPM" ]; then
        echo "<details><summary>全局 npm 包列表（前10个）</summary>" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "$RECENT_NPM" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "</details>" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
fi

# Check pip packages
if command -v pip3 &> /dev/null; then
    PIP_COUNT=$(pip3 list 2>/dev/null | wc -l | tr -d ' ')
    log_info "Python 包数量: $PIP_COUNT"
fi

# Check brew packages
if command -v brew &> /dev/null; then
    BREW_COUNT=$(brew list --versions 2>/dev/null | wc -l | tr -d ' ')
    log_info "Homebrew 包数量: $BREW_COUNT"
    
    # Check for outdated packages
    OUTDATED=$(brew outdated 2>/dev/null | wc -l | tr -d ' ')
    if [ "$OUTDATED" -gt 0 ]; then
        log_info "$OUTDATED 个 Homebrew 包有更新"
    fi
fi

log_ok "包管理器检查完成"

# ============================================================================
# 12. 磁盘空间使用
# ============================================================================
log_section "1️⃣2️⃣ 磁盘空间使用"

DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
DISK_AVAIL=$(df -h / | tail -1 | awk '{print $4}')
DISK_TOTAL=$(df -h / | tail -1 | awk '{print $2}')

if [ "$DISK_USAGE" -gt 90 ]; then
    log_error "磁盘使用率过高: ${DISK_USAGE}% (可用: $DISK_AVAIL / 总计: $DISK_TOTAL)"
elif [ "$DISK_USAGE" -gt 80 ]; then
    log_warn "磁盘使用率较高: ${DISK_USAGE}% (可用: $DISK_AVAIL / 总计: $DISK_TOTAL)"
else
    log_ok "磁盘使用率正常: ${DISK_USAGE}% (可用: $DISK_AVAIL / 总计: $DISK_TOTAL)"
fi

# Check OpenClaw directory size
OC_SIZE=$(du -sh "$OC_DIR" 2>/dev/null | awk '{print $1}')
log_info "OpenClaw 目录大小: $OC_SIZE"

# Check for large files in OpenClaw directory
LARGE_FILES=$(find "$OC_DIR" -type f -size +100M 2>/dev/null | head -5 || echo "")
if [ -n "$LARGE_FILES" ]; then
    log_info "发现大文件 (>100MB)："
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "$LARGE_FILES" | while read file; do
        echo "$(du -h "$file" 2>/dev/null)"
    done >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
fi

# Check workspace size
WORKSPACE_SIZE=$(du -sh "$WORKSPACE_DIR" 2>/dev/null | awk '{print $1}')
log_info "工作区目录大小: $WORKSPACE_SIZE"

# ============================================================================
# 13. OpenClaw 进程状态
# ============================================================================
log_section "1️⃣3️⃣ OpenClaw 进程状态"

# Check if OpenClaw gateway is running
if pgrep -f "openclaw" > /dev/null 2>&1; then
    log_ok "OpenClaw 进程运行中"
    
    # Get process info
    PROC_INFO=$(ps aux | grep -E "[o]penclaw" | head -5 || echo "")
    if [ -n "$PROC_INFO" ]; then
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "$PROC_INFO" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    fi
    
    # Check memory usage
    MEM_USAGE=$(ps aux | grep -E "[o]penclaw" | awk '{sum+=$4} END {printf "%.1f%%", sum}')
    log_info "内存使用: $MEM_USAGE"
    
    # Check CPU usage
    CPU_USAGE=$(ps aux | grep -E "[o]penclaw" | awk '{sum+=$3} END {printf "%.1f%%", sum}')
    log_info "CPU 使用: $CPU_USAGE"
else
    log_error "OpenClaw 进程未运行！"
fi

# Check gateway status
if [ -f "$OC_DIR/openclaw.json" ]; then
    log_ok "配置文件存在"
    CONFIG_SIZE=$(stat -f%z "$OC_DIR/openclaw.json" 2>/dev/null || echo "0")
    log_info "配置文件大小: $CONFIG_SIZE bytes"
else
    log_error "配置文件丢失！"
fi

# Check for error logs
if [ -d "$OC_DIR/logs" ]; then
    RECENT_ERRORS=$(find "$OC_DIR/logs" -type f -mtime -1 -exec grep -l "ERROR\|FATAL" {} \; 2>/dev/null | head -5 || echo "")
    if [ -n "$RECENT_ERRORS" ]; then
        log_warn "最近 24 小时有错误日志："
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "$RECENT_ERRORS" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    fi
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
