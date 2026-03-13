#!/bin/bash
# claude-mem-export.sh - Stop hook: backup claude-mem to Google Drive
# Runs on every session exit. Backs up: SQLite DB, ChromaDB vectors, JSON export.
# Same-day runs overwrite previous backup (full export, date-based naming).
# Retains last 7 days of backups.

LOG="$HOME/.claude-mem/export.log"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"; }

GDRIVE_BASE="$HOME/Library/CloudStorage/GoogleDrive-idragonkid@gmail.com/My Drive"
BACKUP_ROOT="$GDRIVE_BASE/backups/claude-mem/$(hostname -s)"
CLAUDE_MEM_DIR="$HOME/.claude-mem"
SOURCE_DIR="$CLAUDE_MEM_DIR/claude-mem-source"
DATESTAMP=$(date +%Y%m%d)
DAY_DIR="$BACKUP_ROOT/$DATESTAMP"
RETENTION_DAYS=7

# Bail silently if Google Drive not mounted or claude-mem not installed
if [ ! -d "$GDRIVE_BASE" ]; then log "SKIP: Google Drive not mounted"; exit 0; fi
if [ ! -d "$CLAUDE_MEM_DIR" ]; then log "SKIP: claude-mem not installed"; exit 0; fi

log "START backup to $DAY_DIR"

mkdir -p "$DAY_DIR/db" "$DAY_DIR/json" "$DAY_DIR/chroma"

# 1. SQLite backup (safe with WAL mode, no need to stop worker)
if [ -f "$CLAUDE_MEM_DIR/claude-mem.db" ]; then
    sqlite3 "$CLAUDE_MEM_DIR/claude-mem.db" ".backup '$DAY_DIR/db/claude-mem.db'" 2>/dev/null || true
fi

# 2. ChromaDB vector store backup (remove previous same-day backup first)
if [ -d "$CLAUDE_MEM_DIR/chroma" ]; then
    rm -rf "$DAY_DIR/chroma" 2>/dev/null
    cp -r "$CLAUDE_MEM_DIR/chroma" "$DAY_DIR/chroma" 2>/dev/null || true
fi

# 3. JSON export per project (empty query + --project exports all data for that project)
if [ -d "$SOURCE_DIR/node_modules" ] && [ -f "$SOURCE_DIR/scripts/export-memories.ts" ]; then
    PROJ_LIST=$(mktemp)
    sqlite3 "$CLAUDE_MEM_DIR/claude-mem.db" \
        "SELECT DISTINCT project FROM observations WHERE project IS NOT NULL;" \
        > "$PROJ_LIST" 2>/dev/null
    count=0
    while IFS= read -r proj; do
        safe_name=$(echo "$proj" | sed 's/^\.//; s/[ \/]/_/g')
        (cd "$SOURCE_DIR" && npx tsx scripts/export-memories.ts "" \
            "$DAY_DIR/json/$safe_name.json" --project="$proj" 2>/dev/null) || true
        count=$((count + 1))
    done < "$PROJ_LIST"
    rm -f "$PROJ_LIST"
    log "JSON exported $count projects"
elif [ ! -d "$SOURCE_DIR" ]; then
    (git clone --depth 1 https://github.com/thedotmack/claude-mem.git "$SOURCE_DIR" \
        && cd "$SOURCE_DIR" && npm install --silent) >/dev/null 2>&1 &
    log "Source clone started in background"
fi

# 4. Cleanup backups older than 7 days (one find per date directory)
find "$BACKUP_ROOT" -maxdepth 1 -type d -name "20*" -mtime +"$RETENTION_DAYS" -exec rm -rf {} + 2>/dev/null || true

log "DONE backup $DATESTAMP"
