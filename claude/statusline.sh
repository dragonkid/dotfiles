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
cache_write=\(.context_window.current_usage.cache_creation_input_tokens // 0)
cache_read=\(.context_window.current_usage.cache_read_input_tokens // 0)
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

fmt_cost() {
  # Format cost in dollars: <$0.01 -> "<$0.01", else "$X.XX"
  local cents_x100=$1  # cost in hundredths of a cent (integer, to avoid floating point)
  if (( cents_x100 <= 0 )); then printf '$0.00'
  elif (( cents_x100 < 100 )); then printf '<$0.01'
  else printf '$%s' "$(echo "scale=2;$cents_x100/10000" | bc | sed 's/^\./0./')"
  fi
}

# --- Output speed (ms precision via perl, computed early for badge) ---
speed=""
speed_cache="$HOME/.claude/.statusline-speed"
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

# --- Token Cost Tracking (persistent across sessions) ---
# Pricing per 1M tokens (in hundredths of a cent to use integer math):
#   Claude 4 Opus:   input $15, output $75, cache_write $18.75, cache_read $1.50
#   Claude 4 Sonnet: input $3, output $15, cache_write $3.75, cache_read $0.30
#   Claude 3.5 Sonnet: input $3, output $15, cache_write $3.75, cache_read $0.30
#   Claude 3.5 Haiku:  input $0.80, output $4, cache_write $1.00, cache_read $0.08
#   Claude 3 Haiku:    input $0.25, output $1.25, cache_write $0.30, cache_read $0.03
# Stored as: price_per_1M_tokens * 10000 (hundredths of cent), so $15/1M = 150000000 per 1M
# To get cost for N tokens: N * rate / 1M * 10000 = N * rate_x10k / 1M
# We'll use: cost_hundredths_cent = tokens * rate_dollar_per_M * 10000 / 1000000
#          = tokens * rate_dollar_per_M / 100
# To avoid floating point, multiply rate by 100 first: rate_cents_per_M
# cost_hundredths_cent = tokens * rate_cents_per_M / 1000000

get_pricing() {
  # Returns: in_rate out_rate cw_rate cr_rate (all in cents per 1M tokens)
  local mid="$1"
  case "$mid" in
    *opus*|*claude-4-6-opus*|*claude-4-opus*)
      echo "1500 7500 1875 150" ;;
    *claude-4*sonnet*|*claude-3-7*|*claude-3.7*)
      echo "300 1500 375 30" ;;
    *claude-3-5-sonnet*|*claude-3.5-sonnet*)
      echo "300 1500 375 30" ;;
    *haiku*3-5*|*haiku*3.5*)
      echo "80 400 100 8" ;;
    *haiku*)
      echo "25 125 30 3" ;;
    *)
      # Default to Sonnet pricing
      echo "300 1500 375 30" ;;
  esac
}

cost_root="$HOME/.claude/.cost"
today_date=$(date +%Y-%m-%d)
cost_today_dir="$cost_root/$today_date"
mkdir -p "$cost_today_dir"
cost_session_file="$cost_today_dir/session-${session_id}"

session_cost_display=""
today_cost_display=""
total_cost_display=""

if [ -n "$session_id" ] && (( in_tok > 0 || out_tok > 0 )); then
  read -r in_rate out_rate cw_rate cr_rate <<< "$(get_pricing "$model_id")"

  # Session cost from cumulative token counts (conservative: base input rate for all input tokens)
  session_cost_hcent=$(echo "scale=0; ($in_tok * $in_rate + $out_tok * $out_rate) / 1000000" | bc)

  # Write only this session's file (single writer, no lock needed)
  echo "$session_cost_hcent" > "$cost_session_file"

  # Today = sum files in today's directory
  today_hcent=$(awk '{s+=$1} END{print s+0}' "$cost_today_dir"/session-* 2>/dev/null)

  # All-time = sum files across all date directories
  total_hcent=$(awk '{s+=$1} END{print s+0}' "$cost_root"/*/session-* 2>/dev/null)

  session_cost_display=$(fmt_cost "$session_cost_hcent")
  today_cost_display=$(fmt_cost "${today_hcent:-0}")
  total_cost_display=$(fmt_cost "${total_hcent:-0}")
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
tokens="${CYN}$(fmt_tok "$in_tok") in/$(fmt_tok "$out_tok") out${RST}"

# --- Cost display: 💰session | 📅today | Σall-time ---
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
