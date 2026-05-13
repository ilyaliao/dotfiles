#!/bin/sh
# Cursor CLI statusline — stdin: StatusLinePayload (see ~/.cursor/skills-cursor/statusline/SKILL.md)

input=$(cat)

# ╔════════════════════════════════════════════════════════════════════╗
# ║                           INPUT PARSING                            ║
# ╚════════════════════════════════════════════════════════════════════╝

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
  IFS= read -r session_name
  IFS= read -r max_mode
  IFS= read -r param_summary
} <<EOF
$(echo "$input" | jq -r '
  [
    .workspace.current_dir // .cwd // "",
    .model.display_name // "",
    .version // "",
    (
      .worktree.name //
      (if .worktree.path then (.worktree.path | split("/") | last) else empty end) //
      ""
    ),
    ((.context_window.context_window_size // "") | tostring),
    (.context_window.current_usage // {}).input_tokens // 0,
    (.context_window.current_usage // {}).cache_creation_input_tokens // 0,
    (.context_window.current_usage // {}).cache_read_input_tokens // 0,
    ((.context_window.used_percentage | if . == null then "" else . end) | tostring),
    .session_name // "",
    (.model.max_mode // false | tostring),
    .model.param_summary // ""
  ] | .[]
')
EOF

# ╔════════════════════════════════════════════════════════════════════╗
# ║                       CONTEXT % CALCULATION                        ║
# ╚════════════════════════════════════════════════════════════════════╝

tok_total=$(( ${tok_input:-0} + ${tok_cache_create:-0} + ${tok_cache_read:-0} ))
ctx_pct=""
if [ -n "$ctx_used_pct_field" ]; then
  ctx_pct="$ctx_used_pct_field"
elif [ -n "$ctx_size" ] && [ "$tok_total" -gt 0 ]; then
  ctx_pct=$(( (tok_total * 100 + ctx_size / 2) / ctx_size ))
fi

# ╔════════════════════════════════════════════════════════════════════╗
# ║                              GIT INFO                              ║
# ╚════════════════════════════════════════════════════════════════════╝

branch=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# ╔════════════════════════════════════════════════════════════════════╗
# ║                         COLORS & CONSTANTS                         ║
# ╚════════════════════════════════════════════════════════════════════╝

ESC=$(printf '\033')
RESET="${ESC}[0m"
DIM="${ESC}[2m"
CYAN="${ESC}[36m"
YELLOW="${ESC}[33m"
GREEN="${ESC}[32m"
RED="${ESC}[31m"
BOLD_ORANGE="${ESC}[1;38;5;208m"
PINK="${ESC}[38;2;245;189;230m"
BRANCH="${ESC}[38;2;202;211;245m"
TEAL="${ESC}[38;2;139;213;202m"
PEACH="${ESC}[38;2;245;169;127m"
MAUVE="${ESC}[38;2;198;160;246m"

# ╔════════════════════════════════════════════════════════════════════╗
# ║                          HELPER FUNCTIONS                          ║
# ╚════════════════════════════════════════════════════════════════════╝

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

format_tokens() {
  n=$1
  [ -z "$n" ] || [ "$n" = "null" ] && return
  awk -v n="$n" 'BEGIN{
    if (n >= 1000000) { x=n/1000000; if (x==int(x)) printf "%dM", x; else printf "%.1fM", x }
    else if (n >= 1000) { x=n/1000; if (x==int(x)) printf "%dK", x; else printf "%.1fK", x }
    else printf "%d", n
  }'
}

# ╔════════════════════════════════════════════════════════════════════╗
# ║             RENDER LINE 1   —   MODEL · CTX · VERSION              ║
# ╚════════════════════════════════════════════════════════════════════╝

if [ -n "$cwd" ]; then dir=$(basename "$cwd"); else dir="?"; fi
if [ -n "$model" ]; then
  short_model=$(echo "$model" | sed 's/Claude //' | sed 's/ (New)//')
else
  short_model="?"
fi
model_icon=$(pick_model_icon "$ctx_pct")
printf "%s%s  %s%s" "$YELLOW" "$model_icon" "$short_model" "$RESET"
if [ -n "$param_summary" ]; then
  printf " %s%s%s" "$DIM" "$param_summary" "$RESET"
fi

ctx_limit_fmt=""
[ -n "$ctx_size" ] && ctx_limit_fmt=$(format_tokens "$ctx_size")
if [ -n "$ctx_pct" ]; then
  ctx_int=$(printf "%.0f" "$ctx_pct")
  ctx_color=$(pick_color "$ctx_pct")
  printf " %s|%s %s󰧑%s  %s%d%%%s" "$DIM" "$RESET" "$PINK" "$RESET" "$ctx_color" "$ctx_int" "$RESET"
  [ -n "$ctx_limit_fmt" ] && printf " %s(%s)%s" "$DIM" "$ctx_limit_fmt" "$RESET"
fi
[ -n "$version" ] && printf " %s|%s %s%s  %sv%s%s" "$DIM" "$RESET" "$MAUVE" "$RESET" "$MAUVE" "$version" "$RESET"
printf "\n"

# ╔════════════════════════════════════════════════════════════════════╗
# ║                 RENDER LINE 2   —   DIR · BRANCH                   ║
# ╚════════════════════════════════════════════════════════════════════╝

if [ -n "$branch" ]; then
  wt_str=""
  [ -n "$worktree" ] && wt_str=" ${DIM}[${worktree}]${RESET}"
  printf "%s  %s%s %s|%s %s%s  %s%s%s\n" "$CYAN" "$dir" "$RESET" "$DIM" "$RESET" "$BRANCH" "$RESET" "$branch" "$wt_str"
else
  printf "%s  %s%s\n" "$CYAN" "$dir" "$RESET"
fi

# ╔════════════════════════════════════════════════════════════════════╗
# ║             RENDER LINE 3   —   TIME · SESSION · FLAGS            ║
# ╚════════════════════════════════════════════════════════════════════╝

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
printf "%s%s  %s" "$TEAL" "$RESET" "$now_time"
if [ -n "$session_name" ] && ! printf '%s' "$session_name" | grep -qi 'cli usage'; then
  printf " %s|%s %s%s%s" "$DIM" "$RESET" "$PEACH" "$session_name" "$RESET"
fi
if [ "$max_mode" = "true" ]; then
  printf " %s|%s %sMax%s" "$DIM" "$RESET" "$MAUVE" "$RESET"
fi
printf "\n"
