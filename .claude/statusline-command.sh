#!/bin/sh
# Claude Code Statusline
#
# Layout:
#   model_icon model [worktree] | ctx% (limit) | version
#   dir | branch | diff
#   time | session duration | cost ($/h)
#   用量 ████░░░░░░ 40% (剩 N 小時 重置)
#   本周 ██████░░░░ 60% (剩 N 天 N 小時 重置)

input=$(cat)

cwd=$(echo "$input"       | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input"     | jq -r '.model.display_name // empty')
version=$(echo "$input"   | jq -r '.version // empty')
compact_win=$(jq -r '.env.CLAUDE_CODE_AUTO_COMPACT_WINDOW // empty' "$HOME/.claude/settings.json" 2>/dev/null)
ctx_pct=""
if [ -n "$compact_win" ]; then
  ctx_pct=$(echo "$input" | jq --arg win "$compact_win" -r '
    (
      (.context_window.current_usage.input_tokens // 0) +
      (.context_window.current_usage.cache_creation_input_tokens // 0) +
      (.context_window.current_usage.cache_read_input_tokens // 0)
    ) as $used
    | if $used > 0
      then ($used * 100 / ($win | tonumber))
      else empty end
  ')
fi
if [ -z "$ctx_pct" ]; then
  ctx_pct=$(echo "$input" | jq -r '
    .context_window.used_percentage //
    (if .context_window.context_window_size and .context_window.current_usage.input_tokens
     then (.context_window.current_usage.input_tokens * 100 / .context_window.context_window_size)
     else empty end)
  ')
fi
worktree=$(echo "$input"  | jq -r '.workspace.git_worktree // empty')
ctx_size=$(echo "$input"  | jq -r '.context_window.context_window_size // empty')

branch=""
diff_add=""
diff_del=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    stat=$(git -C "$cwd" diff HEAD --shortstat 2>/dev/null)
    diff_add=$(echo "$stat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')
    diff_del=$(echo "$stat" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+')

  fi
fi

usage_5h=$(echo "$input"     | jq -r '.rate_limits.five_hour.used_percentage // empty')
usage_5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
usage_7d=$(echo "$input"     | jq -r '.rate_limits.seven_day.used_percentage // empty')
usage_7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
total_in=$(echo "$input"  | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
session_duration_s=""
if [ -n "$duration_ms" ]; then
  session_duration_s=$(( duration_ms / 1000 ))
fi

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
ORANGE="${ESC}[38;5;208m"
BOLD_ORANGE="${ESC}[1;38;5;208m"
PINK="${ESC}[38;2;245;189;230m"
BRANCH="${ESC}[38;2;202;211;245m"
TEAL="${ESC}[38;2;139;213;202m"
PEACH="${ESC}[38;2;245;169;127m"
SAPPHIRE="${ESC}[38;2;125;196;228m"
GREEN_CT="${ESC}[38;2;166;218;149m"
YELLOW_CT="${ESC}[38;2;238;212;159m"
MAUVE="${ESC}[38;2;198;160;246m"

# Pick a color for a usage percentage (5-step: <20 green, <40 teal, <60 yellow, <80 bold orange, >=80 red)
pick_color() {
  pct=$1
  if [ -z "$pct" ]; then
    printf "%s" "$DIM"
    return
  fi
  int=$(printf "%.0f" "$pct")
  if [ "$int" -ge 80 ]; then
    printf "%s" "$RED"
  elif [ "$int" -ge 60 ]; then
    printf "%s" "$BOLD_ORANGE"
  elif [ "$int" -ge 40 ]; then
    printf "%s" "$YELLOW"
  elif [ "$int" -ge 20 ]; then
    printf "%s" "$TEAL"
  else
    printf "%s" "$GREEN"
  fi
}
# Pick a model icon by ctx percentage (chill -> panic -> dead)
pick_model_icon() {
  pct=$1
  if [ -z "$pct" ]; then
    printf "%s" "󱙺"
    return
  fi
  int=$(printf "%.0f" "$pct")
  if [ "$int" -ge 100 ]; then
    printf "%s" "󱚢"
  elif [ "$int" -ge 80 ]; then
    printf "%s" "󱚞"
  elif [ "$int" -ge 60 ]; then
    printf "%s" "󱚠"
  elif [ "$int" -ge 40 ]; then
    printf "%s" "󱚤"
  elif [ "$int" -ge 20 ]; then
    printf "%s" "󱜚"
  else
    printf "%s" "󱙺"
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

# Format token count with K/M suffix (e.g. 127398 -> "127.4K", 1234567 -> "1.2M")
format_tokens() {
  n=$1
  if [ -z "$n" ] || [ "$n" = "null" ]; then
    return
  fi
  awk -v n="$n" 'BEGIN{
    if (n >= 1000000) { x=n/1000000; if (x==int(x)) printf "%dM", x; else printf "%.1fM", x }
    else if (n >= 1000) { x=n/1000; if (x==int(x)) printf "%dK", x; else printf "%.1fK", x }
    else printf "%d", n
  }'
}

# Format "2h 30m, at 14:30" (relative + absolute) given ISO-8601 timestamp
format_reset() {
  ts=$1
  [ -z "$ts" ] && return
  now=$(date +%s)
  diff=$(( ts - now ))
  [ $diff -le 0 ] && return

  d=$(( diff / 86400 ))
  h=$(( (diff % 86400) / 3600 ))
  m=$(( (diff % 3600) / 60 ))
  if [ $d -gt 0 ]; then
    rel=$(printf "%d 天 %d 小時" "$d" "$h")
  elif [ $h -gt 0 ]; then
    rel=$(printf "%d 小時 %d 分" "$h" "$m")
  else
    rel=$(printf "%d 分" "$m")
  fi

  printf "剩 %s 重置" "$rel"
}

# Line 1: directory + model
if [ -n "$cwd" ]; then
  dir=$(basename "$cwd")
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
model_icon=$(pick_model_icon "$ctx_pct")
printf "%s%s  %s%s%s" "$YELLOW" "$model_icon" "$short_model" "$RESET" "$wt_str"
ctx_limit=""
if [ -n "$compact_win" ]; then
  ctx_limit="$compact_win"
elif [ -n "$ctx_size" ]; then
  ctx_limit="$ctx_size"
fi
ctx_limit_fmt=""
[ -n "$ctx_limit" ] && ctx_limit_fmt=$(format_tokens "$ctx_limit")
if [ -n "$ctx_pct" ]; then
  ctx_int=$(printf "%.0f" "$ctx_pct")
  ctx_color=$(pick_color "$ctx_pct")
  printf " %s|%s %s󰧑%s  %s%d%%%s" "$DIM" "$RESET" "$PINK" "$RESET" "$ctx_color" "$ctx_int" "$RESET"
  [ -n "$ctx_limit_fmt" ] && printf " %s(%s)%s" "$DIM" "$ctx_limit_fmt" "$RESET"
fi
if [ -n "$version" ]; then
  printf " %s|%s %s%s  %sv%s%s" "$DIM" "$RESET" "$MAUVE" "$RESET" "$MAUVE" "$version" "$RESET"
fi
printf "\n"
if [ -n "$branch" ]; then
  diff_str=""
  if [ -n "$diff_add" ] || [ -n "$diff_del" ]; then
    diff_str=" ${DIM}|${RESET} ${MAUVE}${RESET}  "
    [ -n "$diff_add" ] && diff_str="${diff_str}${GREEN}+${diff_add}${RESET}"
    [ -n "$diff_del" ] && diff_str="${diff_str} ${RED}-${diff_del}${RESET}"
  fi
  printf "%s  %s%s %s|%s %s%s  %s%s\n" "$CYAN" "$dir" "$RESET" "$DIM" "$RESET" "$BRANCH" "$RESET" "$branch" "$diff_str"
else
  printf "%s  %s%s\n" "$CYAN" "$dir" "$RESET"
fi

# Line 3: 現在時間 + session 時長
h=$(date +%H)
case $h in
  03|04|05) period="凌晨" ;;
  06|07|08|09|10) period="早上" ;;
  11|12) period="中午" ;;
  13|14|15|16|17) period="下午" ;;
  18|19|20|21|22) period="晚上" ;;
  *) period="半夜" ;;
esac
hour_12=$(date +%I | sed 's/^0//')
now_time="${period} ${hour_12}:$(date +%M)"
duration_str=""
if [ -n "$session_duration_s" ] && [ "$session_duration_s" -gt 0 ]; then
  d_h=$(( session_duration_s / 3600 ))
  d_m=$(( (session_duration_s % 3600) / 60 ))
  d_ss=$(( session_duration_s % 60 ))
  if [ $d_h -gt 0 ]; then
    duration_str=$(printf "%d 小時 %d 分" "$d_h" "$d_m")
  elif [ $d_m -gt 0 ]; then
    duration_str=$(printf "%d 分 %d 秒" "$d_m" "$d_ss")
  else
    duration_str=$(printf "%d 秒" "$d_ss")
  fi
fi
cost_str=""
if [ -n "$total_cost" ]; then
  cost_fmt=$(awk -v c="$total_cost" 'BEGIN{printf "%.2f", c}')
  rate_suffix=""
  if [ -n "$session_duration_s" ] && [ "$session_duration_s" -gt 60 ]; then
    rate=$(awk -v c="$total_cost" -v s="$session_duration_s" 'BEGIN{printf "%.2f", c * 3600 / s}')
    rate_suffix=" ${DIM}(\$${rate}/h)${RESET}"
  fi
  cost_str=$(printf "%s%s  %s%s" "$YELLOW_CT" "$RESET" "$cost_fmt" "$rate_suffix")
fi
printf "%s%s  %s" "$TEAL" "$RESET" "$now_time"
if [ -n "$duration_str" ]; then
  printf " %s|%s %s%s  %s" "$DIM" "$RESET" "$PEACH" "$RESET" "$duration_str"
fi
if [ -n "$cost_str" ]; then
  printf " %s|%s %s" "$DIM" "$RESET" "$cost_str"
fi
printf "\n"

# Line 4: Usage (5h)
if [ -n "$usage_5h" ]; then
  u5_int=$(printf "%.0f" "$usage_5h")
  u5_color=$(pick_color "$usage_5h")
  bar=$(render_bar "$usage_5h" "$u5_color")
  reset_str=$(format_reset "$usage_5h_reset")
  if [ -n "$reset_str" ]; then
    printf "%s用量%s %s %s%3d%%%s %s(%s)%s\n" "$DIM" "$RESET" "$bar" "$u5_color" "$u5_int" "$RESET" "$DIM" "$reset_str" "$RESET"
  else
    printf "%s用量%s %s %s%3d%%%s\n" "$DIM" "$RESET" "$bar" "$u5_color" "$u5_int" "$RESET"
  fi
fi

# Line 5: Weekly (7d)
if [ -n "$usage_7d" ]; then
  u7_int=$(printf "%.0f" "$usage_7d")
  u7_color=$(pick_color "$usage_7d")
  bar=$(render_bar "$usage_7d" "$u7_color")
  reset_str=$(format_reset "$usage_7d_reset")
  if [ -n "$reset_str" ]; then
    printf "%s本周%s %s %s%3d%%%s %s(%s)%s\n" "$DIM" "$RESET" "$bar" "$u7_color" "$u7_int" "$RESET" "$DIM" "$reset_str" "$RESET"
  else
    printf "%s本周%s %s %s%3d%%%s\n" "$DIM" "$RESET" "$bar" "$u7_color" "$u7_int" "$RESET"
  fi
fi
