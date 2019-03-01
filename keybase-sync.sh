#!/bin/bash

set -euxo pipefail

DESTINATION="/Volumes/Keybase (juliano)/private/juliaaano/"

cp -af $HOME/.zsh_history "$DESTINATION"
cp -af $HOME/.aws/aws-env.sh "$DESTINATION"
cp -af $HOME/.kube/config "$DESTINATION"

