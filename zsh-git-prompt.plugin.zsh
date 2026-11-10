# zsh-git-prompt: an informative git prompt for zsh.
#
# Pure zsh, no Python or compiled helper: each prompt runs a single
#   git status --porcelain=v2 --branch
# and parses its output.
#
# Usage: source this file, then put $(git_super_status) in PROMPT or RPROMPT.

autoload -Uz add-zsh-hook colors && colors
setopt PROMPT_SUBST

# Appearance. Set any of these before or after sourcing to override.
: ${ZSH_THEME_GIT_PROMPT_PREFIX="("}
: ${ZSH_THEME_GIT_PROMPT_SUFFIX=")"}
: ${ZSH_THEME_GIT_PROMPT_SEPARATOR="|"}
: ${ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg_bold[magenta]%}"}
: ${ZSH_THEME_GIT_PROMPT_HASH_PREFIX=":"}
: ${ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[red]%}%{●%G%}"}
: ${ZSH_THEME_GIT_PROMPT_CONFLICTS="%{$fg[red]%}%{✖%G%}"}
: ${ZSH_THEME_GIT_PROMPT_CHANGED="%{$fg[blue]%}%{✚%G%}"}
: ${ZSH_THEME_GIT_PROMPT_BEHIND="%{↓%G%}"}
: ${ZSH_THEME_GIT_PROMPT_AHEAD="%{↑%G%}"}
: ${ZSH_THEME_GIT_PROMPT_UNTRACKED="%{…%G%}"}
: ${ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}%{✔%G%}"}

# Read the repo state into GIT_* variables. Clears them outside a repo.
update_current_git_vars() {
  emulate -L zsh
  typeset -g __CURRENT_GIT_STATUS= GIT_BRANCH=
  typeset -gi GIT_AHEAD=0 GIT_BEHIND=0 GIT_STAGED=0 GIT_CONFLICTS=0 GIT_CHANGED=0 GIT_UNTRACKED=0

  local out
  out=$(command git --no-optional-locks status --porcelain=v2 --branch 2>/dev/null) || return 0

  local line oid head xy
  local -a ab
  for line in ${(f)out}; do
    case $line in
      ('# branch.oid '*)  oid=${line#'# branch.oid '} ;;
      ('# branch.head '*) head=${line#'# branch.head '} ;;
      ('# branch.ab '*)
        ab=(${=line#'# branch.ab '})
        GIT_AHEAD=${ab[1]#+}
        GIT_BEHIND=${ab[2]#-}
        ;;
      ([12]' '*)
        xy=${line[3,4]}
        [[ $xy[1] != . ]] && (( ++GIT_STAGED ))
        [[ $xy[2] != . ]] && (( ++GIT_CHANGED ))
        ;;
      ('u '*) (( ++GIT_CONFLICTS )) ;;
      ('? '*) (( ++GIT_UNTRACKED )) ;;
    esac
  done

  if [[ $head == '(detached)' ]]; then
    GIT_BRANCH=$ZSH_THEME_GIT_PROMPT_HASH_PREFIX${oid[1,7]}
  else
    GIT_BRANCH=$head
  fi
  __CURRENT_GIT_STATUS=1
}

# Refresh before every prompt. With ZSH_THEME_GIT_PROMPT_CACHE set, refresh
# only after changing directory or running a git-like command (for huge repos).
_zsh_git_prompt_preexec() {
  case $2 in
    (git*|hub*|gh*|stg*|lazygit*|tig*) __EXECUTED_GIT_COMMAND=1 ;;
  esac
}

_zsh_git_prompt_precmd() {
  if [[ -z $ZSH_THEME_GIT_PROMPT_CACHE || -n $__EXECUTED_GIT_COMMAND || -n $__ZSH_GIT_PROMPT_DIRTY_CWD ]]; then
    update_current_git_vars
    unset __EXECUTED_GIT_COMMAND __ZSH_GIT_PROMPT_DIRTY_CWD
  fi
}

_zsh_git_prompt_chpwd() {
  __ZSH_GIT_PROMPT_DIRTY_CWD=1
}

typeset -g __ZSH_GIT_PROMPT_DIRTY_CWD=1  # make sure the first prompt refreshes
add-zsh-hook preexec _zsh_git_prompt_preexec
add-zsh-hook precmd  _zsh_git_prompt_precmd
add-zsh-hook chpwd   _zsh_git_prompt_chpwd

# Render the prompt segment from the GIT_* variables. Prints nothing outside a repo.
git_super_status() {
  emulate -L zsh
  [[ -n $__CURRENT_GIT_STATUS ]] || return 0

  local rc="%{${reset_color}%}"
  local s=$ZSH_THEME_GIT_PROMPT_PREFIX$ZSH_THEME_GIT_PROMPT_BRANCH${GIT_BRANCH//\%/%%}$rc
  (( GIT_BEHIND ))    && s+=$ZSH_THEME_GIT_PROMPT_BEHIND$GIT_BEHIND$rc
  (( GIT_AHEAD ))     && s+=$ZSH_THEME_GIT_PROMPT_AHEAD$GIT_AHEAD$rc
  s+=$ZSH_THEME_GIT_PROMPT_SEPARATOR
  (( GIT_STAGED ))    && s+=$ZSH_THEME_GIT_PROMPT_STAGED$GIT_STAGED$rc
  (( GIT_CONFLICTS )) && s+=$ZSH_THEME_GIT_PROMPT_CONFLICTS$GIT_CONFLICTS$rc
  (( GIT_CHANGED ))   && s+=$ZSH_THEME_GIT_PROMPT_CHANGED$GIT_CHANGED$rc
  (( GIT_UNTRACKED )) && s+=$ZSH_THEME_GIT_PROMPT_UNTRACKED$rc
  (( GIT_STAGED + GIT_CONFLICTS + GIT_CHANGED + GIT_UNTRACKED )) || s+=$ZSH_THEME_GIT_PROMPT_CLEAN
  s+=$rc$ZSH_THEME_GIT_PROMPT_SUFFIX
  print -rn -- $s
}
