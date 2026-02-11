#!/bin/bash
read -r input

eval "$(echo "$input" | jq -r '@sh "model=\(.model.display_name // "?") remaining=\(.context_window.remaining_percentage // "?") in_tok=\(.context_window.total_input_tokens // 0) out_tok=\(.context_window.total_output_tokens // 0) added=\(.cost.total_lines_added // 0) removed=\(.cost.total_lines_removed // 0) duration_ms=\(.cost.total_duration_ms // 0)"')"
dir=$(echo "$input" | jq -r '.workspace.project_dir // .cwd')
dir="${dir/#$HOME/~}"

fmt_tokens() {
  local n=$1
  if (( n >= 1000000 )); then
    printf '%.1fM' "$(echo "scale=1; $n/1000000" | bc)"
  elif (( n >= 1000 )); then
    printf '%.1fk' "$(echo "scale=1; $n/1000" | bc)"
  else
    printf '%d' "$n"
  fi
}

tokens="$(fmt_tokens $in_tok) in/$(fmt_tokens $out_tok) out"

duration_s=$(( duration_ms / 1000 ))
duration_m=$(( duration_s / 60 ))
duration_h=$(( duration_m / 60 ))
if (( duration_h > 0 )); then
  duration="${duration_h}h$((duration_m % 60))m"
elif (( duration_m > 0 )); then
  duration="${duration_m}m$((duration_s % 60))s"
else
  duration="${duration_s}s"
fi

green='\033[32m'
yellow='\033[33m'
cyan='\033[36m'
red='\033[31m'
dim='\033[2m'
reset='\033[0m'

if [[ "$remaining" =~ ^[0-9]+$ ]] && (( remaining <= 20 )); then
  ctx_color=$red
elif [[ "$remaining" =~ ^[0-9]+$ ]] && (( remaining <= 50 )); then
  ctx_color=$yellow
else
  ctx_color=$green
fi

printf "${green}[%s]${reset} ctx: ${ctx_color}%s%%${reset} | ${yellow}%s${reset} | ${dim}%s${reset} | ${green}+%s${reset} ${red}-%s${reset} | ${cyan}%s${reset}" "$model" "$remaining" "$tokens" "$duration" "$added" "$removed" "$dir"
