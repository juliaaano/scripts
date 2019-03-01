#!/bin/bash

gpg-connect-agent killagent /bye 1> /dev/null
gpg-agent --daemon
echo export GPG_TTY=$(tty)

