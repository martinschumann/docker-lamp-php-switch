if [ -f /usr/lib/git-core/git-sh-prompt ]; then
    . /usr/lib/git-core/git-sh-prompt

    GIT_PS1_SHOWDIRTYSTATE=true
    GIT_PS1_SHOWSTASHSTATE=true
    GIT_PS1_SHOWUNTRACKEDFILES=true
    GIT_PS1_SHOWCOLORHINTS=true

    PROMPT_COMMAND='__git_ps1 "\[\033[01;31m\][\u@\H]\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]" " \\$ "'
else
    PS1="\[\033[01;31m\][\u@\H]\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \\$ "
fi
