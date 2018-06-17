#!/usr/bin/env bash

set -o errexit

VERSION=0.4
DOWNLOAD=https://github.com/blablacar/acserver/releases/download/v${VERSION}-blablacar/acserver-v${VERSION}-blablacar-linux-amd64.tar.gz

function install_acserver() {
	if [[ -e /usr/bin/acserver ]] ; then
		if [ "0.4-blablacar-eb43341" == "$(acserver -V | grep version | awk '{print $3}')" ] ; then
			return
		fi
	fi

	wget -q -O /tmp/acserver.tar.gz "${DOWNLOAD}"

	tar -C /tmp -xvf /tmp/acserver.tar.gz

	mv -v /tmp/acserver-v${VERSION}-blablacar-linux-amd64/acserver /usr/bin/acserver
	chmod +x /usr/bin/acserver
	mkdir -pv /var/lib/acserver
}

function configure_acserver() {
	if [[ -e /etc/acserver/config.yml ]] ; then
		return
	fi

	mkdir -pv /etc/acserver
	cat <<EOT > /etc/acserver/config.yml
api:
  serverName: aci
  port: 3000
  https: false
  username: admin
  password: password
storage:
  rootPath: /var/lib/acserver
  unsigned: true
  allowOverride: true
EOT
}

install_acserver
configure_acserver
