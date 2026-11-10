# zsh-git-prompt

An informative git prompt for zsh, written in plain zsh. It needs nothing but `git` (2.11 or later): no Python and no compiled helper.

Each prompt runs a single `git status --porcelain=v2 --branch` and parses the result in zsh. That takes about 8 ms in a typical repo.

Based on [olivierverdier/zsh-git-prompt](https://github.com/olivierverdier/zsh-git-prompt). It uses the same symbols and `ZSH_THEME_GIT_PROMPT_*` variables, so existing themes keep working.

## What it looks like

- `(main↑3|✚1)`: on `main`, 3 commits ahead of the upstream, 1 file changed but not staged
- `(status|●2)`: on `status`, 2 files staged
- `(main|✚7…)`: on `main`, 7 files changed, some untracked files
- `(main|✖2✚3)`: on `main`, 2 conflicts, 3 files changed
- `(experimental↓2↑3|✔)`: diverged (upstream has 2 new commits, you have 3), otherwise clean
- `(:70c2952|✔)`: detached HEAD at `70c2952`, clean

| Symbol | Meaning |
|--------|---------|
| `✔`    | clean working tree |
| `●n`   | `n` staged files |
| `✖n`   | `n` files with merge conflicts |
| `✚n`   | `n` changed but unstaged files |
| `…`    | untracked files present |
| `↑n`   | ahead of the upstream by `n` commits |
| `↓n`   | behind the upstream by `n` commits |
| `:abc1234` | detached HEAD (a commit hash, not a branch) |

## Install

**Plain source:**

```zsh
git clone https://github.com/szerintedmi/zsh-git-prompt ~/.zsh/zsh-git-prompt
# in ~/.zshrc
source ~/.zsh/zsh-git-prompt/zsh-git-prompt.plugin.zsh
```

**antidote:** add `szerintedmi/zsh-git-prompt` to your plugins file.

**zinit:** `zinit light szerintedmi/zsh-git-prompt`

**oh-my-zsh:**

```zsh
git clone https://github.com/szerintedmi/zsh-git-prompt ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-git-prompt
# in ~/.zshrc
plugins=(... zsh-git-prompt)
```

Then use `git_super_status` in your prompt (single quotes matter):

```zsh
PROMPT='%B%~%b$(git_super_status) %# '
# or on the right:
RPROMPT='$(git_super_status)'
```

## Customize

Set any of these in `~/.zshrc`, before or after sourcing the plugin:

```zsh
ZSH_THEME_GIT_PROMPT_PREFIX="("
ZSH_THEME_GIT_PROMPT_SUFFIX=")"
ZSH_THEME_GIT_PROMPT_SEPARATOR="|"
ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg_bold[magenta]%}"
ZSH_THEME_GIT_PROMPT_HASH_PREFIX=":"
ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[red]%}%{●%G%}"
ZSH_THEME_GIT_PROMPT_CONFLICTS="%{$fg[red]%}%{✖%G%}"
ZSH_THEME_GIT_PROMPT_CHANGED="%{$fg[blue]%}%{✚%G%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{↓%G%}"
ZSH_THEME_GIT_PROMPT_AHEAD="%{↑%G%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{…%G%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}%{✔%G%}"
```

The raw values are also available as `$GIT_BRANCH`, `$GIT_AHEAD`, `$GIT_BEHIND`, `$GIT_STAGED`, `$GIT_CONFLICTS`, `$GIT_CHANGED` and `$GIT_UNTRACKED` if you want to build your own segment.

### Very large repos

By default the status refreshes before every prompt. In very large repos you can set `ZSH_THEME_GIT_PROMPT_CACHE=1`. The status then refreshes only after you change directory or run a git-like command (`git`, `gh`, `hub`, `stg`, `tig`, `lazygit`).

## Test

```zsh
zsh test/run.zsh
```

The tests build throwaway repos in a temp directory and check clean, untracked, changed, staged, rename, conflict, detached and diverged states.
