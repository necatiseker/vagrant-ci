#!/usr/bin/env bash
set -x

apt-get -qq -y update
apt-get install -qq -y ca-certificates curl wget unzip ntp

curl --silent -Lo /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
curl --silent -Lo /bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl --silent -Lo /bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x /bin/{jq,cfssl,cfssljson}

timedatectl set-timezone Europe/Istanbul

systemctl enable ntp.service
systemctl start ntp.service

