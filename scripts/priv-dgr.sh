#!/usr/bin/env bash

set -o errexit

VERSION=93
DOWNLOAD=https://github.com/blablacar/dgr/releases/download/v${VERSION}/dgr-v${VERSION}-linux-amd64.tar.gz

function install_dgr() {
	if [[ -e /usr/bin/dgr ]] ; then
		if [ "${VERSION}" == "$(dgr version | grep version | awk '{print $3}')" ] ; then
			return
		fi
	fi

	wget -q -O /tmp/dgr.tar.gz "${DOWNLOAD}"

	tar -C /tmp -xvf /tmp/dgr.tar.gz

	mv -v /tmp/dgr-v${VERSION}-linux-amd64/dgr /usr/bin/dgr
	chmod +x /usr/bin/dgr
}

function configure_dgr_globaling() {
	if [[ -e /home/vagrant/.config/dgr/config.yml ]] ; then
		return
	fi

	mkdir -pv /home/vagrant/.config/dgr
	cat <<EOT > /home/vagrant/.config/dgr/config.yml
targetWorkDir: /target
rkt:
  path: /usr/local/bin/rkt
  insecureOptions: [http, image]
  dir: /var/lib/rkt
  localConfig: /etc/rkt
  systemConfig: /usr/lib/rkt
  userConfig:
  trustKeysFromHttps: false
  noStore: false
  storeOnly: false
push:
  url: http://aci.local
EOT
}

install_dgr
configure_dgr_globaling
