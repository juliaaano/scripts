#!/bin/bash

gpg-connect-agent killagent /bye 1> /dev/null
gpg-agent --daemon
echo export GPG_TTY=$(tty)
echo export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

