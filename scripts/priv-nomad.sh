#!/usr/bin/env bash
set -x

VER=0.8.4
URL=https://releases.hashicorp.com/nomad/${VER}/nomad_${VER}_linux_amd64.zip
DEV=eth1
ADDR=$(ip addr show dev $DEV | grep -oP 'inet \K[0-9.]+')

function install_nomad() {
	if [[ -e /usr/bin/nomad ]] ; then
		if [ "v${VER}" == "$(nomad version | head -n1 | awk '{print $2}')" ] ; then
			return
		fi
	fi

	wget -q -O /tmp/nomad.zip ${URL}

	unzip -d /tmp /tmp/nomad.zip
	mv -v /tmp/nomad /usr/bin/nomad
	chmod +x /usr/bin/nomad

	mkdir -pv /etc/nomad.d
	mkdir -pv /etc/nomad.d/server
  mkdir -pv /etc/nomad.d/tls
	mkdir -pv /var/lib/nomad
}


function tls_keys_nomad() {
	cd /vagrant/ca
	
	cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname="localhost,client.global.nomad,nomad,global.nomad,server.global.nomad,127.0.0.1,${ADDR}" \
    -profile=default \
    nomad-csr.json | cfssljson -bare nomad

	cat "ca.pem" > /etc/nomad.d/tls/ca.pem
	cat "nomad.pem" > /etc/nomad.d/tls/nomad.pem
	cat "nomad-key.pem" > /etc/nomad.d/tls/nomad-key.pem 
}

function configure_nomad() {
	if [[ -e /etc/nomad.d/server/server.hcl ]] ; then
		return
	fi

	cat <<EOT > /etc/nomad.d/server/server.hcl
bind_addr = "0.0.0.0"

advertise {
  http = "${ADDR}:4646"
  rpc = "${ADDR}:4647"
  serf = "${ADDR}:4648"
}

data_dir  = "/var/lib/nomad"
log_level = "INFO"

server {
  enabled = true
  bootstrap_expect = 1
}

client {
  enabled = true
  node_class = "system"
  network_interface = "${DEV}"
  network_speed = 1000
  options {
    "driver.raw_exec.enable" = "1"
  }
}

tls {
  ca_file = "/etc/nomad.d/tls/ca.pem"
  cert_file = "/etc/nomad.d/tls/nomad.pem"
  http = true
  key_file = "/etc/nomad.d/tls/nomad-key.pem"
  rpc = true
  verify_https_client = false
}

vault {
  address = "https://${ADDR}:8200"
  ca_file = "/etc/vault/tls/ca.pem"
  cert_file = "/etc/vault/tls/vault.pem"
  create_from_role = "nomad-cluster"
  enabled = true
  key_file = "/etc/vault/tls/vault-key.pem"
  token = ""
}
EOT
}

function start_nomad() {
	if [[ -e /etc/systemd/system/nomad.service ]] ; then
		return
	fi

	cat <<EOT > /etc/systemd/system/nomad.service
[Unit]
Description=Nomad Agent
Documentation=https://nomadproject.io/docs/

[Service]
TimeoutStartSec=0
ExecStart=/usr/bin/nomad agent -config=/etc/nomad.d/server/server.hcl
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOT

# systemctl enable nomad
# systemctl start nomad
}

install_nomad
tls_keys_nomad
configure_nomad
start_nomad