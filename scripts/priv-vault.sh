#!/usr/bin/env bash
set -x

VER=0.10.2
URL=https://releases.hashicorp.com/vault/${VER}/vault_${VER}_linux_amd64.zip
DEV=eth1
ADDR=$(ip addr show dev $DEV | grep -oP 'inet \K[0-9.]+')

function install_vault() {
	if [[ -e /usr/bin/vault ]] ; then
		if [ "v${VER}" == "$(vault version | head -n1 | awk '{print $2}')" ] ; then
			return
		fi
	fi

	wget -q -O /tmp/vault.zip ${URL}

	unzip -d /tmp /tmp/vault.zip
	mv -v /tmp/vault /usr/bin/vault
	chmod +x /usr/bin/vault

	mkdir -pv /etc/vault/
  mkdir -pv /etc/vault/server
  mkdir -pv /etc/vault/tls
}

function tls_keys_vault() {
  cd /vagrant/ca

	cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname="vault,localhost,vault.dc1.consul,vault.service.consul,127.0.0.1,${ADDR}" \
    -profile=default \
    vault-csr.json | cfssljson -bare vault

  cat vault.pem ca.pem > vault-combined.pem

	cat "ca.pem" > /etc/vault/tls/ca.pem
	cat "vault.pem" > /etc/vault/tls/vault.pem
	cat "vault-key.pem" > /etc/vault/tls/vault-key.pem
	cat "vault-combined.pem" > /etc/vault/tls/vault-combined.pem	
}

function configure_vault() {
	if [[ -e /etc/vault/server/vault.hcl ]] ; then
		return
	fi

	cat <<EOT > /etc/vault/server/vault.hcl
disable_mlock = true
ui = true
    
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_cert_file = "/etc/vault/tls/vault-combined.pem"
  tls_client_ca_file = "/etc/vault/tls/ca.pem"
  tls_key_file = "/etc/vault/tls/vault-key.pem"
  tls_min_version = "tls12"
  tls_require_and_verify_client_cert = "false"
}

storage "consul" {
  address = "127.0.0.1:8500"
  path = "vault/"
} 
EOT
}

function start_vault() {
	if [[ -e /etc/systemd/system/vault.service ]] ; then
		return
	fi

	cat <<EOT > /etc/systemd/system/vault.service
[Unit]
Description=vault Agent
Documentation=https://www.vaultproject.io/docs/

[Service]
TimeoutStartSec=0
ExecStart=/usr/bin/vault server -config=/etc/vault/server/vault.hcl
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOT

systemctl enable vault
systemctl start vault
}

install_vault
tls_keys_vault
configure_vault
start_vault