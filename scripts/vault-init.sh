#!/usr/bin/env bash
set -x

cd /vagrant
export VAULT_ADDR=https://127.0.0.1:8200
export VAULT_TLS=-tls-skip-verify

vault operator init -address=${VAULT_ADDR} ${VAULT_TLS}> keys.txt

vault operator unseal -address=${VAULT_ADDR} ${VAULT_TLS} $(grep 'Key 1:' keys.txt | awk '{print $NF}')
vault operator unseal -address=${VAULT_ADDR} ${VAULT_TLS} $(grep 'Key 2:' keys.txt | awk '{print $NF}')
vault operator unseal -address=${VAULT_ADDR} ${VAULT_TLS} $(grep 'Key 3:' keys.txt | awk '{print $NF}')

export VAULT_TOKEN=$(grep 'Initial Root Token:' keys.txt | awk '{print substr($NF, 1, length($NF)-1)}')
vault login -address=${VAULT_ADDR} ${VAULT_TLS} ${VAULT_TOKEN}

vault policy write -address=${VAULT_ADDR} ${VAULT_TLS} nomad-server nomad-server-policy.hcl
vault write -address=${VAULT_ADDR} ${VAULT_TLS} /auth/token/roles/nomad-cluster @nomad-cluster-role.json
vault token create -address=${VAULT_ADDR} ${VAULT_TLS} -policy nomad-server -period 72h -orphan

vault status -address=${VAULT_ADDR} ${VAULT_TLS}