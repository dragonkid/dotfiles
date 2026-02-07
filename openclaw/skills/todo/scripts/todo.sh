#!/bin/bash
# TODO management script - Enhanced version
# Usage: todo.sh <action> [args...]

TODO_FILE="$HOME/.openclaw/workspace/TODO.md"

# Ensure TODO.md exists
if [ ! -f "$TODO_FILE" ]; then
    echo "❌ TODO.md not found at $TODO_FILE"
    exit 1
fi

# Helper: Find line numbers by fuzzy text match (case-insensitive)
find_todo_lines() {
    local search="$1"
    grep -in "^- \[ \].*$search" "$TODO_FILE" | cut -d: -f1
}

# Helper: Get TODO text by line number
get_todo_text() {
    local line_num="$1"
    sed -n "${line_num}p" "$TODO_FILE" | sed 's/^- \[ \] //'
}

# Helper: Mark multiple lines as done
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

# Helper: Remove multiple lines
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
        # List all pending TODOs with numbers
        echo "📋 **TODO 列表**"
        echo ""
        grep -n "^- \[ \]" "$TODO_FILE" | while IFS=: read -r num line; do
            text=$(echo "$line" | sed 's/^- \[ \] //')
            # Extract URL from Markdown links [text](url) and show both
            if [[ "$text" =~ \[([^\]]+)\]\(([^\)]+)\) ]]; then
                title="${BASH_REMATCH[1]}"
                url="${BASH_REMATCH[2]}"
                echo "$num. $title"
                echo "   🔗 $url"
            else
                echo "$num. $text"
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
        grep -in "^- \[ \].*$KEYWORD" "$TODO_FILE" | while IFS=: read -r num line; do
            text=$(echo "$line" | sed 's/^- \[ \] //')
            echo "$num. $text"
        done
        ;;
    
    done)
        # Mark TODO(s) as complete - supports: line number, range, or fuzzy text
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
            IFS=',' read -ra NUMS <<< "$TARGET"
            mark_done_multiple "${NUMS[@]}"
            echo "✅ Marked ${#NUMS[@]} item(s) as done"
        # Check if it's a single number
        elif [[ "$TARGET" =~ ^[0-9]+$ ]]; then
            LINE_NUM="$TARGET"
            TODO_TEXT=$(get_todo_text "$LINE_NUM")
            sed -i.bak "${LINE_NUM}s/^- \[ \]/- [x]/" "$TODO_FILE"
            rm -f "${TODO_FILE}.bak"
            echo "✅ Marked as done: $TODO_TEXT"
        # Otherwise, fuzzy text search
        else
            FOUND_LINES=($(find_todo_lines "$TARGET"))
            
            if [ ${#FOUND_LINES[@]} -eq 0 ]; then
                echo "❌ No matching TODO found for: $TARGET"
                exit 1
            elif [ ${#FOUND_LINES[@]} -eq 1 ]; then
                LINE_NUM="${FOUND_LINES[0]}"
                TODO_TEXT=$(get_todo_text "$LINE_NUM")
                sed -i.bak "${LINE_NUM}s/^- \[ \]/- [x]/" "$TODO_FILE"
                rm -f "${TODO_FILE}.bak"
                echo "✅ Marked as done: $TODO_TEXT"
            else
                echo "🔍 Found ${#FOUND_LINES[@]} matches:"
                echo ""
                for line in "${FOUND_LINES[@]}"; do
                    text=$(get_todo_text "$line")
                    echo "$line. $text"
                done
                echo ""
                echo "Please specify line number or be more specific"
                exit 1
            fi
        fi
        ;;
    
    remove)
        # Remove TODO(s) - supports: line number, range, or fuzzy text
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
            IFS=',' read -ra NUMS <<< "$TARGET"
            remove_multiple "${NUMS[@]}"
            echo "✅ Removed ${#NUMS[@]} item(s)"
        # Check if it's a single number
        elif [[ "$TARGET" =~ ^[0-9]+$ ]]; then
            LINE_NUM="$TARGET"
            TODO_TEXT=$(get_todo_text "$LINE_NUM")
            sed -i.bak "${LINE_NUM}d" "$TODO_FILE"
            rm -f "${TODO_FILE}.bak"
            echo "✅ Removed: $TODO_TEXT"
        # Otherwise, fuzzy text search
        else
            FOUND_LINES=($(find_todo_lines "$TARGET"))
            
            if [ ${#FOUND_LINES[@]} -eq 0 ]; then
                echo "❌ No matching TODO found for: $TARGET"
                exit 1
            elif [ ${#FOUND_LINES[@]} -eq 1 ]; then
                LINE_NUM="${FOUND_LINES[0]}"
                TODO_TEXT=$(get_todo_text "$LINE_NUM")
                sed -i.bak "${LINE_NUM}d" "$TODO_FILE"
                rm -f "${TODO_FILE}.bak"
                echo "✅ Removed: $TODO_TEXT"
            else
                echo "🔍 Found ${#FOUND_LINES[@]} matches:"
                echo ""
                for line in "${FOUND_LINES[@]}"; do
                    text=$(get_todo_text "$line")
                    echo "$line. $text"
                done
                echo ""
                echo "Please specify line number or be more specific"
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
