ssh-add-to-agent() 
{ 
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval `ssh-agent -s`;
    fi;
    ssh-add $1
}
