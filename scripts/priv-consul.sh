#!/usr/bin/env bash
set -x

VER=1.1.0
URL=https://releases.hashicorp.com/consul/${VER}/consul_${VER}_linux_amd64.zip
DEV=eth1
ADDR=$(ip addr show dev $DEV | grep -oP 'inet \K[0-9.]+')

function install_consul() {
	if [[ -e /usr/bin/consul ]] ; then
		if [ "v${VER}" == "$(consul version | head -n1 | awk '{print $2}')" ] ; then
			return
		fi
	fi

	wget -q -O /tmp/consul.zip ${URL}

	unzip -d /tmp /tmp/consul.zip
	mv -v /tmp/consul /usr/bin/consul
	chmod +x /usr/bin/consul

	mkdir -pv /etc/consul.d/
	mkdir -pv /etc/consul.d/server
	mkdir -pv /etc/consul.d/tls
	mkdir -pv /var/lib/consul
}

function tls_keys_consul(){
    cd /vagrant/ca

	cfssl gencert -initca ca-csr.json | cfssljson -bare ca

	cfssl gencert \
  	-ca=ca.pem \
	  -ca-key=ca-key.pem \
	  -config=ca-config.json \
	  -hostname="consul,localhost,server.dc1.consul,127.0.0.1,${ADDR}" \
	  -profile=default \
	  consul-csr.json | cfssljson -bare consul

	cat "ca.pem" > /etc/consul.d/tls/ca.pem
	cat "consul.pem" > /etc/consul.d/tls/consul.pem
	cat "consul-key.pem" > /etc/consul.d/tls/consul-key.pem
}

function gossip-encryption-key() {
	if [[ -e ~/.gossip_encryption_key ]] ; then
		return
	fi

	GOSSIP_ENCRYPTION_KEY=$(consul keygen)
	echo $GOSSIP_ENCRYPTION_KEY > ~/.gossip_encryption_key
}


function configure_consul() {
	if [[ -e /etc/consul.d/server/server.json ]] ; then
		return
	fi

	cat <<EOT > /etc/consul.d/server/server.json
{
  "autopilot": {
		"cleanup_dead_servers": true,
		"last_contact_threshold": "300ms",
		"max_trailing_logs": 250,
		"server_stabilization_time": "10s"
  },
  "ca_file": "/etc/consul.d/tls/ca.pem",
  "cert_file": "/etc/consul.d/tls/consul.pem",
  "key_file": "/etc/consul.d/tls/consul-key.pem",
  "ports": {
		"dns": 53,
		"https": 8501
  },
  "verify_outgoing": true,
  "verify_server_hostname": true
}
EOT
}

function start_consul() {
	if [[ -e /etc/systemd/system/consul.service ]] ; then
		return
	fi

	cat <<EOT > /etc/systemd/system/consul.service
[Unit]
Description=Consul Agent
Documentation=https://www.consul.io/docs/

[Service]
TimeoutStartSec=0
ExecStart=/usr/bin/consul agent \
  -advertise=$ADDR \
  -bind=0.0.0.0 \
	-bootstrap-expect=1 \
	-client=0.0.0.0 \
  -config-file=/etc/consul.d/server/server.json \
  -datacenter=dc1 \
  -data-dir=/var/lib/consul \
  -encrypt=$GOSSIP_ENCRYPTION_KEY \
  -server \
  -ui
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

EOT

systemctl enable consul
systemctl start consul
}

install_consul
tls_keys_consul
gossip-encryption-key
configure_consul
start_consul