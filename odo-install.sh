#!/usr/bin/env bash

set -euxo pipefail

DOWNLOAD_URL=$(kubectl get consoleclidownloads odo-cli-downloads -o json | jq '.spec.links[] | select(.text | contains("Download") and contains("odo")) | .href' | tr -d '"')

curl ${DOWNLOAD_URL}/odo-darwin-amd64.tar.gz | tar -xvf - -C ${HOME}/cli

chmod +x ${HOME}/cli/odo

ln -sf ${HOME}/cli/odo /usr/local/bin/odo

echo "end of script"

