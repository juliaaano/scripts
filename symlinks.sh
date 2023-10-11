#!/bin/bash

set -euxo pipefail

for f in *
do
  ln -sf $(realpath $f) /usr/local/bin/"${f%.*}"
done

echo "end of script"

