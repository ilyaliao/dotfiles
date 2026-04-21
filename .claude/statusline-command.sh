#!/bin/sh
input=$(cat)

cwd=$(echo "$input"       | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input"     | jq -r '.model.display_name // empty')
ctx_pct=$(echo "$input" | jq -r '
  .context_window.used_percentage //
  (if .context_window.context_window_size and .context_window.current_usage.input_tokens
   then (.context_window.current_usage.input_tokens * 100 / .context_window.context_window_size)
   else empty end)
')
worktree=$(echo "$input"  | jq -r '.workspace.git_worktree // empty')

usage_5h=$(echo "$input"     | jq -r '.rate_limits.five_hour.used_percentage // empty')
usage_5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
usage_7d=$(echo "$input"     | jq -r '.rate_limits.seven_day.used_percentage // empty')
usage_7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

BAR_W=10
ESC=$(printf '\033')
RESET="${ESC}[0m"
DIM="${ESC}[2m"
CYAN="${ESC}[36m"
YELLOW="${ESC}[33m"
GREEN="${ESC}[32m"
BLUE="${ESC}[94m"
MAGENTA="${ESC}[35m"
RED="${ESC}[31m"
GREY="${ESC}[90m"

# Pick a color for a usage percentage (thresholds: <70 green, <85 yellow, >=85 red)
pick_color() {
  pct=$1
  base=$2
  if [ -z "$pct" ]; then
    printf "%s" "$DIM"
    return
  fi
  int=$(printf "%.0f" "$pct")
  if [ "$int" -ge 85 ]; then
    printf "%s" "$RED"
  elif [ "$int" -ge 70 ]; then
    printf "%s" "$YELLOW"
  else
    printf "%s" "$base"
  fi
}

# Render a progress bar: filled ▇ blocks + empty ░ blocks, width BAR_W
render_bar() {
  pct=$1
  color=$2
  if [ -z "$pct" ]; then
    i=0
    bar=""
    while [ $i -lt $BAR_W ]; do
      bar="${bar}░"
      i=$((i+1))
    done
    printf "%s%s%s" "$DIM" "$bar" "$RESET"
    return
  fi
  int=$(printf "%.0f" "$pct")
  filled=$(( int * BAR_W / 100 ))
  [ $filled -lt 0 ] && filled=0
  [ $filled -gt $BAR_W ] && filled=$BAR_W
  empty=$(( BAR_W - filled ))

  bar=""
  i=0
  while [ $i -lt $filled ]; do bar="${bar}█"; i=$((i+1)); done
  j=0
  empty_part=""
  while [ $j -lt $empty ]; do empty_part="${empty_part}░"; j=$((j+1)); done
  printf "%s%s%s%s%s" "$color" "$bar" "$DIM" "$empty_part" "$RESET"
}

# Format "2h 30m, at 14:30" (relative + absolute) given ISO-8601 timestamp
format_reset() {
  ts=$1
  [ -z "$ts" ] && return
  now=$(date +%s)
  # Parse ISO-8601 (e.g. 2026-04-21T05:00:00Z) with BSD date on macOS
  target=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s 2>/dev/null)
  [ -z "$target" ] && return
  diff=$(( target - now ))
  [ $diff -le 0 ] && return

  d=$(( diff / 86400 ))
  h=$(( (diff % 86400) / 3600 ))
  m=$(( (diff % 3600) / 60 ))
  if [ $d -gt 0 ]; then
    rel=$(printf "%dd %dh" "$d" "$h")
  elif [ $h -gt 0 ]; then
    rel=$(printf "%dh %dm" "$h" "$m")
  else
    rel=$(printf "%dm" "$m")
  fi

  # Absolute wall-clock time in local TZ
  if [ $diff -lt 86400 ]; then
    abs=$(date -r "$target" "+%H:%M")
  else
    abs=$(date -r "$target" "+%b %d %H:%M")
  fi

  printf "%s, at %s" "$rel" "$abs"
}

# Line 1: directory + model
if [ -n "$cwd" ]; then
  dir=$(echo "$cwd" | awk -F'/' '{n=NF; if (n>=2) printf "%s/%s", $(n-1), $n; else printf "%s", $n}')
else
  dir="?"
fi
if [ -n "$model" ]; then
  short_model=$(echo "$model" | sed 's/Claude //' | sed 's/ (New)//')
else
  short_model="?"
fi
wt_str=""
[ -n "$worktree" ] && wt_str=" ${DIM}[${worktree}]${RESET}"
printf "%s[%s]%s  %s%s%s%s\n" "$YELLOW" "$short_model" "$RESET" "$CYAN" "$dir" "$RESET" "$wt_str"

# Line 2: Context
if [ -n "$ctx_pct" ]; then
  ctx_int=$(printf "%.0f" "$ctx_pct")
  ctx_color=$(pick_color "$ctx_pct" "$GREEN")
  bar=$(render_bar "$ctx_pct" "$ctx_color")
  printf "%sContext%s %s %s%3d%%%s\n" "$DIM" "$RESET" "$bar" "$ctx_color" "$ctx_int" "$RESET"
fi

# Line 3: Usage (5h)
if [ -n "$usage_5h" ]; then
  u5_int=$(printf "%.0f" "$usage_5h")
  u5_color=$(pick_color "$usage_5h" "$BLUE")
  bar=$(render_bar "$usage_5h" "$u5_color")
  reset_str=$(format_reset "$usage_5h_reset")
  if [ -n "$reset_str" ]; then
    printf "%sUsage  %s %s %s%3d%%%s %s(resets in %s)%s\n" "$DIM" "$RESET" "$bar" "$u5_color" "$u5_int" "$RESET" "$DIM" "$reset_str" "$RESET"
  else
    printf "%sUsage  %s %s %s%3d%%%s\n" "$DIM" "$RESET" "$bar" "$u5_color" "$u5_int" "$RESET"
  fi
fi

# Line 4: Weekly (7d)
if [ -n "$usage_7d" ]; then
  u7_int=$(printf "%.0f" "$usage_7d")
  u7_color=$(pick_color "$usage_7d" "$MAGENTA")
  bar=$(render_bar "$usage_7d" "$u7_color")
  reset_str=$(format_reset "$usage_7d_reset")
  if [ -n "$reset_str" ]; then
    printf "%sWeekly %s %s %s%3d%%%s %s(resets in %s)%s\n" "$DIM" "$RESET" "$bar" "$u7_color" "$u7_int" "$RESET" "$DIM" "$reset_str" "$RESET"
  else
    printf "%sWeekly %s %s %s%3d%%%s\n" "$DIM" "$RESET" "$bar" "$u7_color" "$u7_int" "$RESET"
  fi
fi
