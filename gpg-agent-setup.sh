#!/bin/bash

# Start gpg-agent only if not already running (preserves YubiKey PIN cache)
gpgconf --launch gpg-agent 2>/dev/null

echo 'export GPG_TTY=$(tty)'
echo export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# Tell the running agent to use the current terminal for pinentry prompts
echo 'gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1'
