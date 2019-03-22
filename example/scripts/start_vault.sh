#!/usr/bin/env bash

set -x

export DEBIAN_FRONTEND=noninteractive
export IPs=$(hostname -I)
export HOST=$(hostname)
export DOMAIN=consul

sudo apt-get install jq -y 

# kill vault
sudo killall vault &>/dev/null

sleep 5

# Create vault configuration
sudo mkdir -p /etc/vault.d

cat << EOF > /etc/vault.d/config.hcl
storage "file" {
  path = "/tmp/data"
}

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_cert_file = "/etc/vault.d/vault.crt"
  tls_key_file = "/etc/vault.d/vault.key"
}

listener "tcp" {
  address   = "172.31.16.31:8200"
  tls_cert_file = "/etc/vault.d/vault.crt"
  tls_key_file = "/etc/vault.d/vault.key"
}

ui = true
api_addr = "https://172.31.16.31:8200"
cluster_addr = "https://172.31.16.31:8201"

EOF

sudo cat << EOF > /etc/vault.d/vault.hcl
path "sys/mounts/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

# List enabled secrets engine
path "sys/mounts" {
  capabilities = [ "read", "list" ]
}

# Work with pki secrets engine
path "pki*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

EOF

################
# openssl conf # Creating openssl conf /// more info  https://www.phildev.net/ssl/opensslconf.html
################
sudo cat << EOF > /usr/lib/ssl/req.conf
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
C = BG
ST = Sofia
L = Sofia
O = chavo
OU = chavo
CN = chavo.consul
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
IP.2 = 172.31.16.31

EOF

######################################
# generate self signed certificate #
######################################
pushd /etc/vault.d
openssl req -x509 -batch -nodes -newkey rsa:2048 -keyout vault.key -out vault.crt -config /usr/lib/ssl/req.conf -days 365
cat vault.crt >> /usr/lib/ssl/certs/ca-certificates.crt
popd

# setup .bash_profile
grep VAULT_ADDR ~/.bash_profile || {
  echo export VAULT_ADDR=https://127.0.0.1:8200 | sudo tee -a ~/.bash_profile
}

systemctl start vault

#########################
# Redirecting vault log #
#########################

sudo -u ubuntu mkdir -p /home/ubuntu/vault/vault_logs
journalctl -f -u vault.service &> /home/ubuntu/vault/vault_logs/${HOST}.log &

echo vault started

sleep 3 

# Initialize Vault

sudo -H -u ubuntu bash -c 'vault operator init > /home/ubuntu/vault/keys.txt'
vault operator unseal $(cat /home/ubuntu/vault/keys.txt | grep "Unseal Key 1:" | cut -c15-)
vault operator unseal $(cat /home/ubuntu/vault/keys.txt | grep "Unseal Key 2:" | cut -c15-)
vault operator unseal $(cat /home/ubuntu/vault/keys.txt | grep "Unseal Key 3:" | cut -c15-)
vault login $(cat /home/ubuntu/vault/keys.txt | grep "Initial Root Token:" | cut -c21-)

# enable secret KV version 1
sudo VAULT_ADDR="https://127.0.0.1:8200" vault secrets enable -version=1 kv
  
# setup .bashrc
grep VAULT_TOKEN ~/.bashrc || {
  echo export VAULT_TOKEN=\`cat /root/.vault-token\` | sudo tee -a ~/.bashrc
}

sudo VAULT_ADDR="https://127.0.0.1:8200" vault secrets enable pki
sudo VAULT_ADDR="https://127.0.0.1:8200" vault secrets tune -max-lease-ttl=87600h pki
sudo VAULT_ADDR="https://127.0.0.1:8200" vault write -field=certificate pki/root/generate/internal common_name="example.com" \
      ttl=87600h > CA_cert.crt
sudo VAULT_ADDR="https://127.0.0.1:8200" vault write pki/config/urls \
      issuing_certificates="https://127.0.0.1:8200/v1/pki/ca" \
      crl_distribution_points="https://127.0.0.1:8200/v1/pki/crl"
sudo VAULT_ADDR="https://127.0.0.1:8200" vault secrets enable -path=pki_int pki
sudo VAULT_ADDR="https://127.0.0.1:8200" vault secrets tune -max-lease-ttl=43800h pki_int
sudo VAULT_ADDR="https://127.0.0.1:8200" vault write -format=json pki_int/intermediate/generate/internal \
        common_name="example.com Intermediate Authority" ttl="43800h" \
        | jq -r '.data.csr' > pki_intermediate.csr
sudo VAULT_ADDR="https://127.0.0.1:8200" vault write -format=json pki/root/sign-intermediate csr=@pki_intermediate.csr \
        format=pem_bundle \
        | jq -r '.data.certificate' > intermediate.cert.pem
sudo VAULT_ADDR="https://127.0.0.1:8200" vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem
sudo VAULT_ADDR="https://127.0.0.1:8200" vault write pki_int/roles/example-dot-com \
        allowed_domains="${DOMAIN}" \
        allow_subdomains=true \
        max_ttl="720h"

# Sealing Vault 
vault operator seal
set +x