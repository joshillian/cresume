# cresume — fzf picker for named Claude Code sessions.
# Source this file from ~/.zshrc. Requires: zsh, fzf, jq.
#
#   cresume          pick from all named sessions
#   cresume <name>   exact name (newest wins) opens directly; else picker pre-filtered to <name>
#
# Config:
#   CRESUME_CMD      command used to resume (default: claude), e.g. "claude --dangerously-skip-permissions"

typeset -g _CRESUME_DIR=${0:A:h}
zmodload -F zsh/stat b:zstat
zmodload -F zsh/datetime b:strftime p:EPOCHSECONDS

# Named sessions (set via `claude -n <name>` or /rename), newest first.
# Output: title<TAB>mtime_epoch<TAB>cwd<TAB>session_id<TAB>transcript_path
_cresume_sessions() {
  local f k v line
  local -a files m grep=(command grep)
  local -A title cwd
  (( $+commands[rg] )) && grep=(command rg --no-heading)  # far faster than BSD grep on GBs of transcripts
  files=($HOME/.claude/projects/*/*.jsonl(N.om))
  (( $#files )) || return 0
  # One pass over all transcripts; a later rename in the same file overwrites the earlier title.
  $grep -H -F '"type":"custom-title"' $files 2>/dev/null \
    | jq -Rr 'capture("^(?<p>.*?\\.jsonl):(?<j>\\{.*)$") | [.p, (.j | fromjson | .customTitle)] | @tsv' 2>/dev/null \
    | while IFS=$'\t' read -r k v; do title[$k]=$v; done
  (( $#title )) || return 0
  for line in ${(f)"$($grep -H -m1 -o '"cwd":"[^"]*"' ${(k)title} 2>/dev/null)"}; do
    k=${line%%:\"cwd\":*} v=${line#*:\"cwd\":\"}
    cwd[$k]=${v%\"}
  done
  for f in $files; do
    [[ -n ${title[$f]} && -n ${cwd[$f]} ]] || continue
    zstat -A m +mtime -- "$f"
    printf '%s\t%s\t%s\t%s\t%s\n' "${title[$f]}" "${m[1]}" "${cwd[$f]}" "${f:t:r}" "$f"
  done
}

cresume() {
  (( $+commands[fzf] )) || { echo "cresume: needs fzf"; return 1; }
  (( $+commands[jq] ))  || { echo "cresume: needs jq"; return 1; }
  local G=$'\e[38;5;114m' D=$'\e[38;5;244m' P=$'\e[38;5;141m' R=$'\e[0m'
  local -a rows f lines
  rows=("${(@f)$(_cresume_sessions | awk -F'\t' '!seen[$1]++')}")  # dedupe titles, newest wins
  [[ -n ${rows[1]} ]] || { echo "cresume: no named sessions"; return 1; }
  local row d age ac dir
  if [[ -n $1 ]]; then
    row=$(printf '%s\n' "${rows[@]}" | awk -F'\t' -v q="$1" 'tolower($1)==tolower(q)' | head -1)
  fi
  if [[ -z $row ]]; then
    # fzf line: display<TAB>title<TAB>mtime<TAB>cwd<TAB>id<TAB>path (only display is shown/searched)
    for row in "${rows[@]}"; do
      f=("${(@ps:\t:)row}")
      d=$(( EPOCHSECONDS - f[2] ))
      if   (( d < 3600 ));   then age="$(( d / 60 ))m ago"; ac=$G
      elif (( d < 86400 ));  then age="$(( d / 3600 ))h ago"; ac=$G
      elif (( d < 604800 )); then age="$(( d / 86400 ))d ago"; ac=
      else strftime -s age '%b %d' ${f[2]}; ac=$D; fi
      [[ ${f[3]} == $HOME ]] && dir='~' || dir=${f[3]:t}
      lines+=("$(printf "%-34.34s $ac%8s$R  $P%s$R" "${f[1]}" "$age" "$dir")"$'\t'"$row")
    done
    row=$(printf '%s\n' "${lines[@]}" | fzf --ansi --delimiter=$'\t' --with-nth=1 --nth=1 \
      --query="$1" --select-1 --layout=reverse --height=85% --border=rounded \
      --border-label=" CRESUME · ${#rows} sessions " --border-label-pos=3 \
      --prompt='› ' --pointer='▌' --marker='·' --info=inline-right \
      --header='enter open · ctrl-/ preview · esc quit' \
      --preview="${(q)_CRESUME_DIR}/bin/cresume-preview {2} {4} {6}" \
      --preview-window='right,50%,wrap,border-left,<110(down,45%,wrap,border-top)' \
      --bind='ctrl-/:toggle-preview' \
      --color='border:244,label:208:bold,prompt:208,pointer:208,marker:208,hl:141,hl+:141:bold,fg+:bold,bg+:236,gutter:-1,info:244,header:244,separator:238,preview-border:238,spinner:208' \
      | cut -f2-)
    [[ -n $row ]] || return 1
  fi
  local -a sel=("${(@ps:\t:)row}")
  [[ -d ${sel[3]} ]] || { echo "cresume: directory gone: ${sel[3]}"; return 1; }
  echo "→ ${sel[1]}  (${sel[3]/#$HOME/~})"
  cd "${sel[3]}" && ${=CRESUME_CMD:-claude} -r "${sel[4]}"
}
