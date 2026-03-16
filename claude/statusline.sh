#!/bin/bash
read -r input

# --- Parse JSON ---
eval "$(echo "$input" | jq -r '@sh "
model_name=\(.model.display_name // "")
model_id=\(.model.id // "")
used_pct=\(.context_window.used_percentage // -1)
remaining_pct=\(.context_window.remaining_percentage // -1)
ctx_size=\(.context_window.context_window_size // 0)
in_tok=\(.context_window.total_input_tokens // 0)
out_tok=\(.context_window.current_usage.output_tokens // 0)
added=\(.cost.total_lines_added // 0)
removed=\(.cost.total_lines_removed // 0)
duration_ms=\(.cost.total_duration_ms // 0)
version=\(.version // "")
"')"
dir_raw=$(echo "$input" | jq -r '.workspace.project_dir // .cwd // ""')

# --- Colors (matching claude-hud) ---
RST='\033[0m'
DIM='\033[2m'
CYN='\033[36m'
YEL='\033[33m'
GRN='\033[32m'
RED='\033[31m'
MAG='\033[35m'

# --- Helpers ---
fmt_tok() {
  local n=$1
  if (( n >= 1000000 )); then printf '%.1fM' "$(echo "scale=1;$n/1000000" | bc)"
  elif (( n >= 1000 )); then printf '%.1fk' "$(echo "scale=1;$n/1000" | bc)"
  else printf '%d' "$n"; fi
}

# --- Output speed (ms precision via perl, computed early for badge) ---
speed=""
speed_cache="$HOME/.claude/.statusline-speed"
now_ms=$(perl -MTime::HiRes=time -e 'printf "%d", time*1000' 2>/dev/null)
if [ -n "$now_ms" ] && [ -f "$speed_cache" ]; then
  IFS= read -r prev_tok < "$speed_cache"
  IFS= read -r prev_ms < <(tail -1 "$speed_cache")
  if [ -n "$prev_tok" ] && [ -n "$prev_ms" ]; then
    dt=$(( out_tok - prev_tok )); dm=$(( now_ms - prev_ms ))
    if (( dt > 0 && dm > 0 && dm <= 3000 )); then
      speed=$(echo "scale=1;$dt*1000/$dm" | bc)
    fi
  fi
fi
[ -n "$now_ms" ] && printf '%s\n%s\n' "$out_tok" "$now_ms" > "$speed_cache"

# --- Model badge: [vX.Y Model | Provider | speed] ---
model="${model_name:-${model_id:-Unknown}}"
provider=""
case "$model_id" in *anthropic.claude-*) provider="Bedrock" ;; esac

ver_tag=""
[ -n "$version" ] && ver_tag="${DIM}v${version}${CYN} "

badge_inner="${ver_tag}${model}"
[ -n "$provider" ] && badge_inner+=" | ${provider}"
[ -n "$speed" ] && badge_inner+=" ${DIM}${speed} tok/s${CYN}"
badge="${CYN}[${badge_inner}]${RST}"

# --- Context bar (10 segments, claude-hud thresholds: <70 green, 70-84 yellow, >=85 red) ---
if [ "$used_pct" -ge 0 ] 2>/dev/null; then pct=$used_pct
elif [ "$remaining_pct" -ge 0 ] 2>/dev/null; then pct=$(( 100 - remaining_pct ))
elif [ "$ctx_size" -gt 0 ]; then pct=$(( in_tok * 100 / ctx_size ))
else pct=0; fi
(( pct > 100 )) && pct=100; (( pct < 0 )) && pct=0

filled=$(( pct / 10 )); empty=$(( 10 - filled ))
if (( pct < 70 )); then pct_color=$GRN
elif (( pct < 85 )); then pct_color=$YEL
else pct_color=$RED; fi
bar=""; for ((i=0;i<filled;i++)); do bar+="█"; done
ctx="${pct_color}${bar}${DIM}"
for ((i=0;i<empty;i++)); do ctx+="░"; done
ctx+="${RST} ${pct_color}${pct}%${RST}"

# --- Project + Git ---
project_git=""
if [ -n "$dir_raw" ]; then
  project="${YEL}$(basename "$dir_raw")${RST}"
  branch=$(git -C "$dir_raw" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    porcelain=$(git -C "$dir_raw" status --porcelain 2>/dev/null)
    dirty=""; [ -n "$porcelain" ] && dirty="*"
    eval "$(echo "$porcelain" | awk '
      /^\?\?/  { u++ }
      /^.M|^M/ { m++ }
      /^A/     { a++ }
      /^.D|^D/ { d++ }
      END { printf "gm=%d ga=%d gd=%d gu=%d", m+0, a+0, d+0, u+0 }
    ')"
    ahead=$(git -C "$dir_raw" rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    behind=$(git -C "$dir_raw" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
    ab=""
    (( ahead > 0 )) && ab+=" ↑${ahead}"
    (( behind > 0 )) && ab+=" ↓${behind}"
    stats=""
    (( gm > 0 )) && stats+=" !${gm}"
    (( ga > 0 )) && stats+=" +${ga}"
    (( gd > 0 )) && stats+=" ✘${gd}"
    (( gu > 0 )) && stats+=" ?${gu}"
    git_part=" ${MAG}git:(${RST}${CYN}${branch}${dirty}${ab}${stats}${RST}${MAG})${RST}"
    project_git="${project}${git_part}"
  else
    project_git="$project"
  fi
fi

# --- Tokens ---
tokens="${DIM}$(fmt_tok "$in_tok") in/$(fmt_tok "$out_tok") out${RST}"

# --- Duration ---
ds=$(( duration_ms / 1000 )); dm=$(( ds / 60 )); dh=$(( dm / 60 ))
if (( dh > 0 )); then dur="${dh}h$((dm % 60))m"
elif (( dm > 0 )); then dur="${dm}m$((ds % 60))s"
else dur="${ds}s"; fi

# --- Lines +/- ---
lines=""
(( added > 0 || removed > 0 )) && lines="${GRN}+${added}${RST} ${RED}-${removed}${RST}"

# --- Assemble ---
parts=("$badge $ctx")
[ -n "$project_git" ] && parts+=("$project_git")
parts+=("$tokens")
parts+=("${DIM}⏱ ${dur}${RST}")
[ -n "$lines" ] && parts+=("$lines")

IFS=' | '
printf '%b' "${parts[*]}"
