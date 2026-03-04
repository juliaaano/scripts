#!/bin/bash

# Kill and restart gpg-agent to recover from sleep/YubiKey disconnect
gpgconf --kill gpg-agent 2>/dev/null
gpg-agent --daemon >/dev/null 2>&1

echo 'export GPG_TTY=$(tty)'
echo 'export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)'

# Tell the agent to use this terminal for pinentry prompts
echo 'gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1'

# Reconnect to YubiKey
echo 'gpg-connect-agent "scd serialno" /bye >/dev/null 2>&1'
