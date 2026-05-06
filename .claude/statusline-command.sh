#!/bin/sh
# Claude Code Statusline
#
# Layout:
#   model_icon model [worktree] | ctx% (limit) | version
#   dir | branch | diff
#   time | session duration | cost
#   用量 ████░░░░░░ 40% (剩 N 小時 重置)
#   本周 ██████░░░░ 60% (剩 N 天 N 小時 重置)

input=$(cat)

# ╔════════════════════════════════════════════════════════════════════╗
# ║                           INPUT PARSING                            ║
# ╚════════════════════════════════════════════════════════════════════╝

# Parse the entire input with one jq invocation. Each field becomes one line;
# missing fields stay empty so `read` keeps positional alignment.
{
  IFS= read -r cwd
  IFS= read -r model
  IFS= read -r version
  IFS= read -r worktree
  IFS= read -r ctx_size
  IFS= read -r tok_input
  IFS= read -r tok_cache_create
  IFS= read -r tok_cache_read
  IFS= read -r ctx_used_pct_field
  IFS= read -r usage_5h
  IFS= read -r usage_5h_reset
  IFS= read -r usage_7d
  IFS= read -r usage_7d_reset
  IFS= read -r total_cost
  IFS= read -r duration_ms
} <<EOF
$(echo "$input" | jq -r '
  [
    .workspace.current_dir // .cwd // "",
    .model.display_name // "",
    .version // "",
    .workspace.git_worktree // "",
    .context_window.context_window_size // "",
    .context_window.current_usage.input_tokens // 0,
    .context_window.current_usage.cache_creation_input_tokens // 0,
    .context_window.current_usage.cache_read_input_tokens // 0,
    .context_window.used_percentage // "",
    .rate_limits.five_hour.used_percentage // "",
    .rate_limits.five_hour.resets_at // "",
    .rate_limits.seven_day.used_percentage // "",
    .rate_limits.seven_day.resets_at // "",
    .cost.total_cost_usd // "",
    .cost.total_duration_ms // ""
  ] | .[]
')
EOF

# ╔════════════════════════════════════════════════════════════════════╗
# ║                       CONTEXT % CALCULATION                        ║
# ╚════════════════════════════════════════════════════════════════════╝

compact_win=$(jq -r '.env.CLAUDE_CODE_AUTO_COMPACT_WINDOW // empty' "$HOME/.claude/settings.json" 2>/dev/null)

# Compute ctx_pct: compact-window-based first, then API field, then context_window_size fallback.
tok_total=$(( ${tok_input:-0} + ${tok_cache_create:-0} + ${tok_cache_read:-0} ))
ctx_pct=""
if [ -n "$compact_win" ] && [ "$tok_total" -gt 0 ]; then
  ctx_pct=$(( (tok_total * 100 + compact_win / 2) / compact_win ))
elif [ -n "$ctx_used_pct_field" ]; then
  ctx_pct="$ctx_used_pct_field"
elif [ -n "$ctx_size" ] && [ "${tok_input:-0}" -gt 0 ]; then
  ctx_pct=$(( (tok_input * 100 + ctx_size / 2) / ctx_size ))
fi

session_duration_s=""
[ -n "$duration_ms" ] && session_duration_s=$(( duration_ms / 1000 ))

_now=$(date +%s)

# ╔════════════════════════════════════════════════════════════════════╗
# ║                              GIT INFO                              ║
# ╚════════════════════════════════════════════════════════════════════╝

branch=""
diff_add=""
diff_del=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    stat=$(git -C "$cwd" diff HEAD --shortstat 2>/dev/null)
    case "$stat" in
      *insertion*) tmp=${stat%% insertion*}; diff_add=${tmp##* } ;;
    esac
    case "$stat" in
      *deletion*) tmp=${stat%% deletion*}; diff_del=${tmp##* } ;;
    esac
  fi
fi

# ╔════════════════════════════════════════════════════════════════════╗
# ║                         COLORS & CONSTANTS                         ║
# ╚════════════════════════════════════════════════════════════════════╝

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

# ╔════════════════════════════════════════════════════════════════════╗
# ║                          HELPER FUNCTIONS                          ║
# ╚════════════════════════════════════════════════════════════════════╝

# 5-step usage palette: <20 green, <40 teal, <60 yellow, <80 bold orange, >=80 red
pick_color() {
  pct=$1
  if [ -z "$pct" ]; then
    printf "%s" "$DIM"
    return
  fi
  int=$(printf "%.0f" "$pct")
  if   [ "$int" -ge 80 ]; then printf "%s" "$RED"
  elif [ "$int" -ge 60 ]; then printf "%s" "$BOLD_ORANGE"
  elif [ "$int" -ge 40 ]; then printf "%s" "$YELLOW"
  elif [ "$int" -ge 20 ]; then printf "%s" "$TEAL"
  else                         printf "%s" "$GREEN"
  fi
}

# Model icon by ctx percentage (chill -> panic -> dead)
pick_model_icon() {
  pct=$1
  if [ -z "$pct" ]; then
    printf "%s" "󱙺"
    return
  fi
  int=$(printf "%.0f" "$pct")
  if   [ "$int" -ge 100 ]; then printf "%s" "󱚢"
  elif [ "$int" -ge 80 ];  then printf "%s" "󱚞"
  elif [ "$int" -ge 60 ];  then printf "%s" "󱚠"
  elif [ "$int" -ge 40 ];  then printf "%s" "󱚤"
  elif [ "$int" -ge 20 ];  then printf "%s" "󱜚"
  else                          printf "%s" "󱙺"
  fi
}

# Progress bar: filled █ + empty ░, total width BAR_W
render_bar() {
  pct=$1
  color=$2
  if [ -z "$pct" ]; then
    bar=""
    i=0
    while [ $i -lt $BAR_W ]; do bar="${bar}░"; i=$((i+1)); done
    printf "%s%s%s" "$DIM" "$bar" "$RESET"
    return
  fi
  int=$(printf "%.0f" "$pct")
  filled=$(( int * BAR_W / 100 ))
  [ $filled -lt 0 ] && filled=0
  [ $filled -gt $BAR_W ] && filled=$BAR_W
  empty=$(( BAR_W - filled ))
  bar=""
  i=0; while [ $i -lt $filled ]; do bar="${bar}█"; i=$((i+1)); done
  empty_part=""
  j=0; while [ $j -lt $empty ]; do empty_part="${empty_part}░"; j=$((j+1)); done
  printf "%s%s%s%s%s" "$color" "$bar" "$DIM" "$empty_part" "$RESET"
}

# Format token count with K/M suffix
format_tokens() {
  n=$1
  [ -z "$n" ] || [ "$n" = "null" ] && return
  awk -v n="$n" 'BEGIN{
    if (n >= 1000000) { x=n/1000000; if (x==int(x)) printf "%dM", x; else printf "%.1fM", x }
    else if (n >= 1000) { x=n/1000; if (x==int(x)) printf "%dK", x; else printf "%.1fK", x }
    else printf "%d", n
  }'
}

# "剩 2 小時 30 分 重置" given an epoch timestamp
format_reset() {
  ts=$1
  [ -z "$ts" ] && return
  diff=$(( ts - _now ))
  [ $diff -le 0 ] && return
  d=$(( diff / 86400 ))
  h=$(( (diff % 86400) / 3600 ))
  m=$(( (diff % 3600) / 60 ))
  if   [ $d -gt 0 ]; then rel=$(printf "%d 天 %d 小時" "$d" "$h")
  elif [ $h -gt 0 ]; then rel=$(printf "%d 小時 %d 分" "$h" "$m")
  else                    rel=$(printf "%d 分" "$m")
  fi
  printf "剩 %s 重置" "$rel"
}

# Render one usage line (用量/本周): label + bar + percent + optional countdown.
# Empty pct degrades to 0%/dim so the line stays present from the first frame.
render_usage_line() {
  label=$1
  pct=$2
  reset_ts=$3
  if [ -n "$pct" ]; then
    int=$(printf "%.0f" "$pct")
    color=$(pick_color "$pct")
  else
    int=0
    color="$DIM"
  fi
  bar=$(render_bar "$pct" "$color")
  reset_str=$(format_reset "$reset_ts")
  if [ -n "$reset_str" ]; then
    printf "%s%s%s %s %s%3d%%%s %s(%s)%s\n" "$DIM" "$label" "$RESET" "$bar" "$color" "$int" "$RESET" "$DIM" "$reset_str" "$RESET"
  else
    printf "%s%s%s %s %s%3d%%%s\n" "$DIM" "$label" "$RESET" "$bar" "$color" "$int" "$RESET"
  fi
}

# ╔════════════════════════════════════════════════════════════════════╗
# ║             RENDER LINE 1   —   MODEL · CTX · VERSION              ║
# ╚════════════════════════════════════════════════════════════════════╝

# Line 1: model icon + name + ctx% + version
if [ -n "$cwd" ]; then dir=$(basename "$cwd"); else dir="?"; fi
if [ -n "$model" ]; then
  short_model=$(echo "$model" | sed 's/Claude //' | sed 's/ (New)//')
else
  short_model="?"
fi
wt_str=""
[ -n "$worktree" ] && wt_str=" ${DIM}[${worktree}]${RESET}"
model_icon=$(pick_model_icon "$ctx_pct")
printf "%s%s  %s%s%s" "$YELLOW" "$model_icon" "$short_model" "$RESET" "$wt_str"

ctx_limit="${compact_win:-$ctx_size}"
ctx_limit_fmt=""
[ -n "$ctx_limit" ] && ctx_limit_fmt=$(format_tokens "$ctx_limit")
if [ -n "$ctx_pct" ]; then
  ctx_int=$(printf "%.0f" "$ctx_pct")
  ctx_color=$(pick_color "$ctx_pct")
  printf " %s|%s %s󰧑%s  %s%d%%%s" "$DIM" "$RESET" "$PINK" "$RESET" "$ctx_color" "$ctx_int" "$RESET"
  [ -n "$ctx_limit_fmt" ] && printf " %s(%s)%s" "$DIM" "$ctx_limit_fmt" "$RESET"
fi
[ -n "$version" ] && printf " %s|%s %s%s  %sv%s%s" "$DIM" "$RESET" "$MAUVE" "$RESET" "$MAUVE" "$version" "$RESET"
printf "\n"

# ╔════════════════════════════════════════════════════════════════════╗
# ║              RENDER LINE 2   —   DIR · BRANCH · DIFF               ║
# ╚════════════════════════════════════════════════════════════════════╝

# Line 2: dir + branch + diff
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

# ╔════════════════════════════════════════════════════════════════════╗
# ║             RENDER LINE 3   —   TIME · DURATION · COST             ║
# ╚════════════════════════════════════════════════════════════════════╝

# Line 3: clock + session duration + cost
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
  if   [ $d_h -gt 0 ]; then duration_str=$(printf "%d 小時 %d 分" "$d_h" "$d_m")
  elif [ $d_m -gt 0 ]; then duration_str=$(printf "%d 分 %d 秒" "$d_m" "$d_ss")
  else                      duration_str=$(printf "%d 秒" "$d_ss")
  fi
fi
cost_str=""
if [ -n "$total_cost" ]; then
  cost_fmt=$(awk -v c="$total_cost" 'BEGIN{printf "%.2f", c}')
  cost_str=$(printf "%s%s  %s" "$YELLOW_CT" "$RESET" "$cost_fmt")
fi
printf "%s%s  %s" "$TEAL" "$RESET" "$now_time"
[ -n "$duration_str" ] && printf " %s|%s %s%s  %s" "$DIM" "$RESET" "$PEACH" "$RESET" "$duration_str"
[ -n "$cost_str" ] && printf " %s|%s %s" "$DIM" "$RESET" "$cost_str"
printf "\n"

# ╔════════════════════════════════════════════════════════════════════╗
# ║                RENDER LINES 4 & 5   —   USAGE BARS                 ║
# ╚════════════════════════════════════════════════════════════════════╝

# Lines 4 & 5: usage bars (always render so they appear from the first frame)
render_usage_line "用量" "$usage_5h" "$usage_5h_reset"
render_usage_line "本周" "$usage_7d" "$usage_7d_reset"
