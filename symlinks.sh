#!/bin/bash

set -euxo pipefail

for f in *
do
  symlink=/usr/local/bin/"${f%.*}"
  rm -f $symlink
  ln -s $(realpath $f) /usr/local/bin/"${f%.*}"
done

echo "end of script"

