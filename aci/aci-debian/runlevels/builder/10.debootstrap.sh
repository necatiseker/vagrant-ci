#!/dgr/bin/busybox sh
set -e
.  /dgr/bin/functions.sh
isLevelEnabled "debug" && set -x

cdebootstrapFile=cdebootstrap-static_0.7.7+b1_amd64.deb
curlFile=curl_7.52.1-5+deb9u5_amd64.deb
keyringFile=debian-archive-keyring_2017.5_all.deb
gpgvFile=gpgv_2.1.18-8~deb9u1_amd64.deb

mkdir /tmp/debootstrap
cd /tmp/debootstrap
wget http://ftp.tr.debian.org/debian/pool/main/c/cdebootstrap/${cdebootstrapFile}
ar -x ${cdebootstrapFile}
cd /
zcat /tmp/debootstrap/data.tar.xz | tar xvh

mkdir /tmp/curl
cd /tmp/curl
wget http://ftp.tr.debian.org/debian/pool/main/c/curl/${curlFile}
ar -x ${curlFile}
cd /
zcat /tmp/curl/data.tar.xz | tar xvh

mkdir /tmp/keyring
cd /tmp/keyring
wget http://ftp.tr.debian.org/debian/pool/main/d/debian-archive-keyring/${keyringFile}
ar -x ${keyringFile}
cd /
zcat /tmp/keyring/data.tar.xz | tar xvh

mkdir /tmp/gpgv
cd /tmp/gpgv
wget http://ftp.tr.debian.org/debian/pool/main/g/gnupg2/${gpgvFile}
ar -x ${gpgvFile}
cd /
zcat /tmp/gpgv/data.tar.xz | tar xvh

echo 'Debootstrapping new Stretch image'
LANG=C /usr/bin/cdebootstrap-static --arch=amd64 --flavour=minimal debian/stretch ${ROOTFS}

rm -Rf  ${ROOTFS}/usr/share/locale/*
