# Perfect Vim shell defaults, sourced from /etc/bash.bashrc.
# Put personal tweaks in ~/.bashrc (it lives in the persistent home volume).
[[ $- == *i* ]] || return 0

alias vim=nvim vi=nvim v=nvim
alias ls='ls --color=auto' ll='ls -lah --color=auto' grep='grep --color=auto'
alias lg=lazygit

# History shared between sessions
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth
shopt -s histappend
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# fzf: Ctrl+R search history, Ctrl+T insert a file path, Alt+C jump to a folder
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
eval "$(fzf --bash)"

[[ -f /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion

# Prompt: pvim ~/folder (branch) $
__pvim_branch() { local b; b=$(git symbolic-ref --short HEAD 2>/dev/null) && printf ' (%s)' "$b"; }
PS1='\[\e[1;35m\]pvim\[\e[0m\] \[\e[1;34m\]\w\[\e[0;33m\]$(__pvim_branch)\[\e[0m\] \$ '
