#!/usr/bin/env bash

set -o errexit

VERSION=1.29.0
DOWNLOAD=https://github.com/rkt/rkt/releases/download/v${VERSION}/rkt-v${VERSION}.tar.gz

function install_rkt() {
	if [[ -e /usr/local/bin/rkt ]] ; then
		if [ "rkt Version: ${VERSION}" == "$(rkt version | head -n1)" ] ; then
			return
		fi
	fi

	wget -q -O /tmp/rkt.tar.gz "${DOWNLOAD}"

	tar -C /tmp -xvf /tmp/rkt.tar.gz

	mv -v /tmp/rkt-v${VERSION}/rkt /usr/local/bin
	mv -v /tmp/rkt-v${VERSION}/*.aci /usr/local/bin
	chmod +x /usr/local/bin/rkt
	mkdir -pv /var/lib/rkt

	groupadd --force --system rkt-admin
	groupadd --force --system rkt
}

function configure_rkt_networking() {
	if [[ -e /etc/rkt/net.d/99-network.conf ]] ; then
		return
	fi

	mkdir -pv /etc/rkt/net.d
	cat <<EOT > /etc/rkt/net.d/99-network.conf
{
  "name": "default",
  "type": "ptp",
  "ipMasq": false,
  "ipam": {
    "type": "host-local",
    "subnet": "172.16.28.0/24",
    "routes": [ { "dst": "0.0.0.0/0" } ]
  }
}
EOT
}

function configure_rkt_authentication() {
	if [[ -e /etc/rkt/auth.d/localhost:3000.json ]] ; then
		return
	fi

	mkdir -pv /etc/rkt/auth.d
	cat <<EOT > /etc/rkt/auth.d/localhost:3000.json
{
	"rktKind": "auth",
	"rktVersion": "v1",
	"domains": ["localhost:3000"],
	"type": "basic",
		"credentials": {
			"user": "admin",
			"password": "password"
		}
}
EOT
}

install_rkt
configure_rkt_authentication
