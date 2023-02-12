#!/bin/bash

set -euxo pipefail

DOWNLOAD_URL=$(kubectl get consoleclidownloads odo-cli-downloads -o json | jq '.spec.links[] | select(.text | contains("Download") and contains("odo")) | .href' | tr -d '"')

curl ${DOWNLOAD_URL}/odo-darwin-amd64.tar.gz | tar -xvf - -C ${HOME}/openshift-cli

chmod +x ${HOME}/openshift-cli/odo

ln -sf ${HOME}/openshift-cli/odo /usr/local/bin/odo

echo "end of script"

