#!/bin/bash

set -euxo pipefail

DOWNLOAD_URL=$(kubectl get consoleclidownloads oc-cli-downloads -o json | jq '.spec.links[] | select(.text | contains("Mac") and contains("x86_64")) | .href' | tr -d '"')

curl ${DOWNLOAD_URL} | tar -xvf - -C ${HOME}/openshift-cli

chmod +x ${HOME}/openshift-cli/oc

ln -sf ${HOME}/openshift-cli/oc /usr/local/bin/oc

echo "end of script"

