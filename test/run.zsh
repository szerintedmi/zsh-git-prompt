#!/usr/bin/env zsh
# Builds throwaway repos in a temp dir and checks the parsed GIT_* values.
# Usage: zsh test/run.zsh

emulate -L zsh
setopt err_return no_unset

ROOT=${0:A:h:h}
source $ROOT/zsh-git-prompt.plugin.zsh

# Hermetic git: ignore the user's and system config.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

TMP=$(mktemp -d)
trap 'rm -rf $TMP' EXIT

integer pass=0 fail=0

# expect <name> "<branch> <ahead> <behind> <staged> <conflicts> <changed> <untracked>"
expect() {
  update_current_git_vars
  local got="$GIT_BRANCH $GIT_AHEAD $GIT_BEHIND $GIT_STAGED $GIT_CONFLICTS $GIT_CHANGED $GIT_UNTRACKED"
  if [[ $got == $2 ]]; then
    (( ++pass )); print -r -- "ok   $1"
  else
    (( ++fail )); print -r -- "FAIL $1: expected '$2', got '$got'"
  fi
}

g() { command git "$@" >/dev/null 2>&1 }

# Not a repo
cd $TMP
update_current_git_vars
if [[ -z $__CURRENT_GIT_STATUS && -z $(git_super_status) ]]; then
  (( ++pass )); print "ok   not a repo"
else
  (( ++fail )); print "FAIL not a repo: got '$(git_super_status)'"
fi

# Fresh repo, no commits
mkdir $TMP/r && cd $TMP/r
g init -b main
expect "empty repo" "main 0 0 0 0 0 0"

print a > a; print b > b
expect "untracked" "main 0 0 0 0 0 2"

g add a b; g commit -m init
expect "clean" "main 0 0 0 0 0 0"

print a2 >> a
expect "changed" "main 0 0 0 0 1 0"

g add a
expect "staged" "main 0 0 1 0 0 0"

print a3 >> a
expect "staged and changed" "main 0 0 1 0 1 0"

g commit -am wip
g mv b c
expect "rename is staged" "main 0 0 1 0 0 0"
g commit -m mv

# Merge conflict
g checkout -b other
print theirs > a; g commit -am theirs
g checkout main
print ours > a; g commit -am ours
g merge other || true
expect "conflict" "main 0 0 0 1 0 0"
g merge --abort

# Detached HEAD
local sha=$(command git rev-parse HEAD)
g checkout --detach
expect "detached" ":${sha[1,7]} 0 0 0 0 0 0"
g checkout main

# Ahead / behind an upstream
g clone $TMP/r $TMP/clone
cd $TMP/clone
expect "tracking, in sync" "main 0 0 0 0 0 0"
print x > x; g add x; g commit -m local1
print y > y; g add y; g commit -m local2
(cd $TMP/r && print z > z && g add z && g commit -m remote1)
g fetch
expect "diverged" "main 2 1 0 0 0 0"

# Branch name with a prompt escape is rendered literally
g checkout -b 'feat%x'
update_current_git_vars
ZSH_THEME_GIT_PROMPT_BRANCH= ZSH_THEME_GIT_PROMPT_CLEAN=C
reset_color=
local rendered=$(git_super_status)
if [[ ${(%)rendered} == '(feat%x|C)' ]]; then
  (( ++pass )); print "ok   percent in branch name"
else
  (( ++fail )); print -r -- "FAIL percent in branch name: got '${(%)rendered}'"
fi

print "\n$pass passed, $fail failed"
(( fail == 0 ))
