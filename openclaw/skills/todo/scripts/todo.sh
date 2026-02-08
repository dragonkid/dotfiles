#!/bin/bash
# TODO management script - Enhanced version
# Usage: todo.sh <action> [args...]

TODO_FILE="$HOME/.openclaw/workspace/TODO.md"

# Ensure TODO.md exists
if [ ! -f "$TODO_FILE" ]; then
    echo "❌ TODO.md not found at $TODO_FILE"
    exit 1
fi

# Helper: Get all pending TODO file line numbers (ordered)
get_todo_file_lines() {
    grep -n "^- \[ \]" "$TODO_FILE" | cut -d: -f1
}

# Helper: Map display index (1-based) to file line number
index_to_line() {
    local idx="$1"
    local lines=($(get_todo_file_lines))
    local arr_idx=$((idx - 1))
    if [ "$arr_idx" -ge 0 ] && [ "$arr_idx" -lt "${#lines[@]}" ]; then
        echo "${lines[$arr_idx]}"
    else
        echo ""
    fi
}

# Helper: Find display indices by fuzzy text match (case-insensitive)
find_todo_indices() {
    local search="$1"
    local lines=($(get_todo_file_lines))
    local results=()
    for i in "${!lines[@]}"; do
        local text=$(sed -n "${lines[$i]}p" "$TODO_FILE")
        if echo "$text" | grep -iq "$search"; then
            results+=($((i + 1)))
        fi
    done
    echo "${results[@]}"
}

# Helper: Get TODO text by file line number
get_todo_text() {
    local line_num="$1"
    sed -n "${line_num}p" "$TODO_FILE" | sed 's/^- \[ \] //'
}

# Helper: Mark multiple file lines as done
mark_done_multiple() {
    local line_nums=("$@")
    local temp_file="${TODO_FILE}.tmp"
    
    cp "$TODO_FILE" "$temp_file"
    for line in "${line_nums[@]}"; do
        sed -i.bak "${line}s/^- \[ \]/- [x]/" "$temp_file"
    done
    mv "$temp_file" "$TODO_FILE"
    rm -f "${TODO_FILE}.bak" "${temp_file}.bak"
}

# Helper: Remove multiple file lines
remove_multiple() {
    local line_nums=("$@")
    local temp_file="${TODO_FILE}.tmp"
    
    cp "$TODO_FILE" "$temp_file"
    # Sort in reverse to delete from bottom up (avoid line number shifting)
    for line in $(printf '%s\n' "${line_nums[@]}" | sort -rn); do
        sed -i.bak "${line}d" "$temp_file"
    done
    mv "$temp_file" "$TODO_FILE"
    rm -f "${TODO_FILE}.bak" "${temp_file}.bak"
}

ACTION="$1"

# Smart command matching with abbreviations
case "$ACTION" in
    l|li|lis|list)
        ACTION="list"
        shift
        ;;
    d|do|don|done|complete|finish)
        ACTION="done"
        shift
        ;;
    r|rm|rem|remo|remov|remove|delete|del)
        ACTION="remove"
        shift
        ;;
    a|ad|add)
        ACTION="add"
        shift
        ;;
    s|se|sea|sear|searc|search|find)
        ACTION="search"
        shift
        ;;
    "")
        # Empty input: show list
        ACTION="list"
        ;;
    *)
        # Unknown command: treat as add
        ACTION="add"
        # Don't shift - keep all args for the item
        ;;
esac

case "$ACTION" in
    add)
        # Add a new TODO item
        ITEM="$*"
        if [ -z "$ITEM" ]; then
            echo "❌ Usage: /todo <description>"
            exit 1
        fi
        
        # Append to TODO.md
        echo "" >> "$TODO_FILE"
        echo "- [ ] $ITEM" >> "$TODO_FILE"
        echo "✅ Added: $ITEM"
        ;;
    
    list)
        # List all pending TODOs with sequential numbers
        echo "📋 **TODO 列表**"
        echo ""
        idx=0
        grep -n "^- \[ \]" "$TODO_FILE" | while IFS=: read -r num line; do
            idx=$((idx + 1))
            text=$(echo "$line" | sed 's/^- \[ \] //')
            # Extract URL from Markdown links [text](url) and show both
            if [[ "$text" =~ \[([^\]]+)\]\(([^\)]+)\) ]]; then
                title="${BASH_REMATCH[1]}"
                url="${BASH_REMATCH[2]}"
                echo "$idx. $title"
                echo "   🔗 $url"
            else
                echo "$idx. $text"
            fi
        done
        ;;
    
    search)
        # Search TODOs by keyword
        KEYWORD="$*"
        if [ -z "$KEYWORD" ]; then
            echo "❌ Usage: /todo search <keyword>"
            exit 1
        fi
        
        echo "🔍 搜索结果："
        echo ""
        idx=0
        grep -n "^- \[ \]" "$TODO_FILE" | while IFS=: read -r num line; do
            idx=$((idx + 1))
            if echo "$line" | grep -iq "$KEYWORD"; then
                text=$(echo "$line" | sed 's/^- \[ \] //')
                echo "$idx. $text"
            fi
        done
        ;;
    
    done)
        # Mark TODO(s) as complete - supports: index number, range, or fuzzy text
        TARGET="$*"
        if [ -z "$TARGET" ]; then
            echo "❌ Usage: /todo done <number|range|text>"
            echo "Examples:"
            echo "  /todo done 3"
            echo "  /todo done 1,3,5"
            echo "  /todo done 探索"
            exit 1
        fi
        
        # Check if it's a comma-separated list of numbers
        if [[ "$TARGET" =~ ^[0-9,]+$ ]]; then
            IFS=',' read -ra INDICES <<< "$TARGET"
            FILE_LINES=()
            for idx in "${INDICES[@]}"; do
                fl=$(index_to_line "$idx")
                if [ -n "$fl" ]; then
                    FILE_LINES+=("$fl")
                fi
            done
            if [ ${#FILE_LINES[@]} -eq 0 ]; then
                echo "❌ No valid items found"
                exit 1
            fi
            mark_done_multiple "${FILE_LINES[@]}"
            echo "✅ Marked ${#FILE_LINES[@]} item(s) as done"
        # Check if it's a single number
        elif [[ "$TARGET" =~ ^[0-9]+$ ]]; then
            LINE_NUM=$(index_to_line "$TARGET")
            if [ -z "$LINE_NUM" ]; then
                echo "❌ Item #$TARGET not found"
                exit 1
            fi
            TODO_TEXT=$(get_todo_text "$LINE_NUM")
            sed -i.bak "${LINE_NUM}s/^- \[ \]/- [x]/" "$TODO_FILE"
            rm -f "${TODO_FILE}.bak"
            echo "✅ Marked as done: $TODO_TEXT"
        # Otherwise, fuzzy text search
        else
            FOUND_INDICES=($(find_todo_indices "$TARGET"))
            
            if [ ${#FOUND_INDICES[@]} -eq 0 ]; then
                echo "❌ No matching TODO found for: $TARGET"
                exit 1
            elif [ ${#FOUND_INDICES[@]} -eq 1 ]; then
                IDX="${FOUND_INDICES[0]}"
                LINE_NUM=$(index_to_line "$IDX")
                TODO_TEXT=$(get_todo_text "$LINE_NUM")
                sed -i.bak "${LINE_NUM}s/^- \[ \]/- [x]/" "$TODO_FILE"
                rm -f "${TODO_FILE}.bak"
                echo "✅ Marked as done: $TODO_TEXT"
            else
                echo "🔍 Found ${#FOUND_INDICES[@]} matches:"
                echo ""
                for idx in "${FOUND_INDICES[@]}"; do
                    fl=$(index_to_line "$idx")
                    text=$(get_todo_text "$fl")
                    echo "$idx. $text"
                done
                echo ""
                echo "Please specify item number or be more specific"
                exit 1
            fi
        fi
        ;;
    
    remove)
        # Remove TODO(s) - supports: index number, range, or fuzzy text
        TARGET="$*"
        if [ -z "$TARGET" ]; then
            echo "❌ Usage: /todo remove <number|range|text>"
            echo "Examples:"
            echo "  /todo remove 3"
            echo "  /todo rm 1,3,5"
            echo "  /todo del 探索"
            exit 1
        fi
        
        # Check if it's a comma-separated list of numbers
        if [[ "$TARGET" =~ ^[0-9,]+$ ]]; then
            IFS=',' read -ra INDICES <<< "$TARGET"
            FILE_LINES=()
            for idx in "${INDICES[@]}"; do
                fl=$(index_to_line "$idx")
                if [ -n "$fl" ]; then
                    FILE_LINES+=("$fl")
                fi
            done
            if [ ${#FILE_LINES[@]} -eq 0 ]; then
                echo "❌ No valid items found"
                exit 1
            fi
            remove_multiple "${FILE_LINES[@]}"
            echo "✅ Removed ${#FILE_LINES[@]} item(s)"
        # Check if it's a single number
        elif [[ "$TARGET" =~ ^[0-9]+$ ]]; then
            LINE_NUM=$(index_to_line "$TARGET")
            if [ -z "$LINE_NUM" ]; then
                echo "❌ Item #$TARGET not found"
                exit 1
            fi
            TODO_TEXT=$(get_todo_text "$LINE_NUM")
            sed -i.bak "${LINE_NUM}d" "$TODO_FILE"
            rm -f "${TODO_FILE}.bak"
            echo "✅ Removed: $TODO_TEXT"
        # Otherwise, fuzzy text search
        else
            FOUND_INDICES=($(find_todo_indices "$TARGET"))
            
            if [ ${#FOUND_INDICES[@]} -eq 0 ]; then
                echo "❌ No matching TODO found for: $TARGET"
                exit 1
            elif [ ${#FOUND_INDICES[@]} -eq 1 ]; then
                IDX="${FOUND_INDICES[0]}"
                LINE_NUM=$(index_to_line "$IDX")
                TODO_TEXT=$(get_todo_text "$LINE_NUM")
                sed -i.bak "${LINE_NUM}d" "$TODO_FILE"
                rm -f "${TODO_FILE}.bak"
                echo "✅ Removed: $TODO_TEXT"
            else
                echo "🔍 Found ${#FOUND_INDICES[@]} matches:"
                echo ""
                for idx in "${FOUND_INDICES[@]}"; do
                    fl=$(index_to_line "$idx")
                    text=$(get_todo_text "$fl")
                    echo "$idx. $text"
                done
                echo ""
                echo "Please specify item number or be more specific"
                exit 1
            fi
        fi
        ;;
    
    *)
        echo "❌ Unknown action: $ACTION"
        echo "Usage: /todo {add|list|done|remove|search} [args...]"
        echo "Abbreviations: l=list, d=done, r=remove, s=search"
        exit 1
        ;;
esac
