#!/bin/bash

set -euo pipefail

GNUPGHOME=$(PWD)/${1:-.gnupg}

if [ -d $GNUPGHOME ]; then
    echo "echo location $GNUPGHOME already exists"
    exit 1
fi

PINENTRY=$(which pinentry-mac || true)

if [ -z $PINENTRY ]; then
    echo "echo pinentry-mac not found"
    exit 1
fi

echo export GNUPGHOME=$GNUPGHOME

mkdir -p $GNUPGHOME
chmod 700 $GNUPGHOME

cat << EOF > $GNUPGHOME/gpg.conf
#auto-key-locate keyserver
#keyserver hkps://hkps.pool.sks-keyservers.net
#keyserver-options no-honor-keyserver-url
#keyserver-options ca-cert-file=/etc/sks-keyservers.netCA.pem

personal-cipher-preferences AES256 AES192 AES CAST5
personal-digest-preferences SHA512 SHA384 SHA256 SHA224
default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed
cert-digest-algo SHA512
s2k-digest-algo SHA512
s2k-cipher-algo AES256

charset utf-8
fixed-list-mode
no-comments
no-emit-version
keyid-format short
list-options show-uid-validity
verify-options show-uid-validity
with-fingerprint
require-cross-certification

use-agent
EOF

cat << EOF > $GNUPGHOME/scdaemon.conf
disable-ccid
EOF

chmod 600 $GNUPGHOME/gpg.conf

cat << EOF > $GNUPGHOME/gpg-agent.conf
enable-ssh-support
pinentry-program $PINENTRY
default-cache-ttl 3600
max-cache-ttl 14400
default-cache-ttl-ssh 3600
max-cache-ttl-ssh 14400
EOF

chmod 600 $GNUPGHOME/gpg-agent.conf

curl -sSL https://www.juliaaano.com/key.asc | gpg --homedir $GNUPGHOME --import -
#curl -sSL https://keybase.io/juliaaano/key.asc | gpg --import -

gpg-connect-agent killagent /bye 1> /dev/null
gpg-agent --daemon
echo export GPG_TTY=$(tty)

echo "# DO NOT forget to eval"
echo "# eval \$(gpg-config)"
echo "# eval \$(curl -s https://raw.githubusercontent.com/juliaaano/scripts/master/gpg-config.sh | bash)"
echo "# Restart the gpg agent"
echo "# eval \$(curl -s https://raw.githubusercontent.com/juliaaano/scripts/master/gpg-agent-setup.sh | bash)"
