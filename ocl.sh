#!/bin/bash

set -euo pipefail

resolve_url() {
  local input="$1"
  if [[ "$input" =~ ^[a-z0-9]{5}$ ]]; then
    echo "https://api.cluster-${input}.dynamic.redhatworkshops.io:6443/"
  else
    echo "$input"
  fi
}

if [ $# -eq 3 ]; then
  URL=$(resolve_url "$1")
  USERNAME="$2"
  PASSWORD="$3"
elif [ $# -eq 2 ]; then
  URL=$(resolve_url "$1")
  USERNAME="admin"
  PASSWORD="$2"
else
  echo "Usage: ocl <api-url|guid> [username] <password>"
  echo "  username defaults to 'admin' if omitted"
  echo "  a 5-char guid resolves to https://api.cluster-<guid>.dynamic.redhatworkshops.io:6443/"
  exit 1
fi

CMD="oc login --insecure-skip-tls-verify --server=$URL --username=$USERNAME --password=$PASSWORD"
echo "$CMD"
echo
$CMD
