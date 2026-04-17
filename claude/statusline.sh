#!/bin/bash
read -r input

# --- Parse JSON ---
eval "$(echo "$input" | jq -r '@sh "
model_name=\(.model.display_name // "")
model_id=\(.model.id // "")
session_id=\(.session_id // "")
used_pct=\(.context_window.used_percentage // -1)
remaining_pct=\(.context_window.remaining_percentage // -1)
ctx_size=\(.context_window.context_window_size // 0)
in_tok=\(.context_window.total_input_tokens // 0)
out_tok=\(.context_window.total_output_tokens // 0)
cur_out_tok=\(.context_window.current_usage.output_tokens // 0)
cost_usd=\(.cost.total_cost_usd // 0)
added=\(.cost.total_lines_added // 0)
removed=\(.cost.total_lines_removed // 0)
duration_ms=\(.cost.total_duration_ms // 0)
version=\(.version // "")
"')"
dir_raw=$(echo "$input" | jq -r '.workspace.project_dir // .cwd // ""')

# --- Colors ---
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

fmt_cost() {
  # Input: cost in cents (integer, e.g. 150 = $1.50)
  local cents=$1
  if (( cents <= 0 )); then printf '$0.00'
  elif (( cents < 1 )); then printf '<$0.01'
  else
    local d=$(( cents / 100 )); local c=$(( cents % 100 ))
    printf '$%d.%02d' "$d" "$c"
  fi
}

# --- Output speed (per-session cache to avoid cross-session pollution) ---
speed=""
if [ -n "$session_id" ]; then
  speed_cache="$HOME/.claude/.statusline-speed-${session_id}"
  now_ms=$(perl -MTime::HiRes=time -e 'printf "%d", time*1000' 2>/dev/null)
  if [ -n "$now_ms" ] && [ -f "$speed_cache" ]; then
    IFS= read -r prev_tok < "$speed_cache"
    IFS= read -r prev_ms < <(tail -1 "$speed_cache")
    if [ -n "$prev_tok" ] && [ -n "$prev_ms" ]; then
      dt=$(( cur_out_tok - prev_tok )); dm=$(( now_ms - prev_ms ))
      if (( dt > 0 && dm > 0 && dm <= 3000 )); then
        speed=$(echo "scale=1;$dt*1000/$dm" | bc)
      fi
    fi
  fi
  [ -n "$now_ms" ] && printf '%s\n%s\n' "$cur_out_tok" "$now_ms" > "$speed_cache"
fi

# --- Cost Tracking (delta accumulation, uses official cost.total_cost_usd) ---
# cost_usd is the session's cumulative cost from Claude Code (accurate, server-side).
# We convert to cents (integer) for file storage and cross-session summing.
# Each session file stores: line1=accumulated_cents, line2=last_seen_cost_usd
# Delta = current cost_usd - last_seen → added to accumulated total.
# If delta < 0 (compaction reset cost_usd), treat current as fresh baseline.

cost_root="$HOME/.claude/.cost"
today_date=$(date +%Y-%m-%d)
cost_today_dir="$cost_root/$today_date"

session_cost_display=""
today_cost_display=""
total_cost_display=""

if [ -n "$session_id" ]; then
  mkdir -p "$cost_today_dir"
  cost_session_file="$cost_today_dir/session-${session_id}"

  # Convert cost_usd (float) to cents (integer): $1.234 → 123
  cost_cents=$(echo "scale=0; $cost_usd * 100 / 1" | bc 2>/dev/null)
  cost_cents=${cost_cents:-0}

  # Read previous state
  prev_accum=0
  prev_cost_cents=0
  if [ -f "$cost_session_file" ]; then
    IFS= read -r prev_accum < "$cost_session_file"
    IFS= read -r prev_cost_cents < <(sed -n '2p' "$cost_session_file")
    prev_accum=${prev_accum:-0}
    prev_cost_cents=${prev_cost_cents:-0}
  fi

  # Calculate delta
  delta=$(( cost_cents - prev_cost_cents ))
  if (( delta < 0 )); then
    # Compaction or reset: treat current cost as a fresh chunk
    delta=$cost_cents
  fi
  accum=$(( prev_accum + delta ))

  # Write: line1=accumulated_cents, line2=last_seen_cost_cents
  printf '%d\n%d\n' "$accum" "$cost_cents" > "$cost_session_file"

  # Today = sum line1 (accumulated cents) from all session files in today's dir
  today_cents=$(awk 'NR%2==1{s+=$1} END{print s+0}' "$cost_today_dir"/session-* 2>/dev/null)

  # All-time = sum line1 across all date directories
  total_cents=$(awk 'NR%2==1{s+=$1} END{print s+0}' "$cost_root"/*/session-* 2>/dev/null)

  session_cost_display=$(fmt_cost "$accum")
  today_cost_display=$(fmt_cost "${today_cents:-0}")
  total_cost_display=$(fmt_cost "${total_cents:-0}")
fi

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

# --- Context bar (10 segments: <70 green, 70-84 yellow, >=85 red) ---
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

# --- Project + Git (no eval, pure awk) ---
project_git=""
if [ -n "$dir_raw" ]; then
  project="${YEL}$(basename "$dir_raw")${RST}"
  branch=$(git -C "$dir_raw" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    porcelain=$(git -C "$dir_raw" status --porcelain 2>/dev/null)
    dirty=""; [ -n "$porcelain" ] && dirty="*"
    read -r gm ga gd gu <<< "$(echo "$porcelain" | awk '
      /^\?\?/  { u++ }
      /^.M|^M/ { m++ }
      /^A/     { a++ }
      /^.D|^D/ { d++ }
      END { printf "%d %d %d %d", m+0, a+0, d+0, u+0 }
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
tokens="${CYN}$(fmt_tok "$in_tok") in/$(fmt_tok "$out_tok") out${RST}"

# --- Cost display ---
cost_part=""
if [ -n "$session_cost_display" ]; then
  cost_part="💰${YEL}${session_cost_display}${RST}"
  cost_part+=" 📅${YEL}${today_cost_display}${RST}"
  cost_part+=" ${DIM}Σ${RST}${YEL}${total_cost_display}${RST}"
fi

# --- Duration ---
ds=$(( duration_ms / 1000 )); dm=$(( ds / 60 )); dh=$(( dm / 60 ))
if (( dh > 0 )); then dur="${dh}h$((dm % 60))m"
elif (( dm > 0 )); then dur="${dm}m$((ds % 60))s"
else dur="${ds}s"; fi

# --- Lines +/- ---
lines=""
(( added > 0 || removed > 0 )) && lines="${GRN}+${added}${RST} ${RED}-${removed}${RST}"

# --- Assemble (two lines) ---
line1=("$badge $ctx")
[ -n "$project_git" ] && line1+=("$project_git")

line2=()
[ -n "$cost_part" ] && line2+=("$cost_part")
line2+=("$tokens")
line2+=("${MAG}⏱ ${dur}${RST}")
[ -n "$lines" ] && line2+=("$lines")

IFS=' | '
line2_str="${line2[0]}"
for ((i=1;i<${#line2[@]};i++)); do line2_str+=" ${line2[$i]}"; done
printf '%b\n%b' "${line1[*]}" "$line2_str"
