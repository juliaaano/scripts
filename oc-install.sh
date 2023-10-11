#!/usr/bin/env bash

set -euxo pipefail

DOWNLOAD_URL=$(kubectl get consoleclidownloads oc-cli-downloads -o json | jq '.spec.links[] | select(.text | contains("Mac") and contains("ARM 64")) | .href' | tr -d '"')

curl --insecure ${DOWNLOAD_URL} | tar -xvf - -C ${HOME}/cli

chmod +x ${HOME}/cli/oc

ln -sf ${HOME}/cli/oc /usr/local/bin/oc

echo "end of script"

