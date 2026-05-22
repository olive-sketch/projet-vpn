#!/bin/bash
set -euo pipefail

EASYRSA_DIR="/etc/easy-rsa"
OPENVPN_DIR="/etc/openvpn/server"
CLIENTS=("user1" "user2")

apt-get update -y
apt-get install -y openvpn easy-rsa

make-cadir "$EASYRSA_DIR"
cd "$EASYRSA_DIR"

cat > vars <<'VARS'
set_var EASYRSA_REQ_COUNTRY    "FR"
set_var EASYRSA_REQ_PROVINCE   "Ile-de-France"
set_var EASYRSA_REQ_CITY       "Paris"
set_var EASYRSA_REQ_ORG        "MonOrg"
set_var EASYRSA_REQ_EMAIL      "admin@monorg.fr"
set_var EASYRSA_REQ_OU         "VPN"
set_var EASYRSA_KEY_SIZE       4096
set_var EASYRSA_ALGO           rsa
set_var EASYRSA_CA_EXPIRE      3650
set_var EASYRSA_CERT_EXPIRE    825
set_var EASYRSA_DIGEST         "sha256"
VARS

./easyrsa init-pki
./easyrsa --batch build-ca nopass
./easyrsa --batch gen-req server nopass
./easyrsa --batch sign-req server server
./easyrsa gen-dh

openvpn --genkey secret "$EASYRSA_DIR/pki/ta.key"
./easyrsa gen-crl

mkdir -p "$OPENVPN_DIR"
cp pki/ca.crt              "$OPENVPN_DIR/"
cp pki/issued/server.crt   "$OPENVPN_DIR/"
cp pki/private/server.key  "$OPENVPN_DIR/"
cp pki/dh.pem              "$OPENVPN_DIR/"
cp pki/ta.key              "$OPENVPN_DIR/"
cp pki/crl.pem             "$OPENVPN_DIR/"

chmod 600 "$OPENVPN_DIR/server.key" "$OPENVPN_DIR/ta.key"
mkdir -p /var/log/openvpn

for CLIENT in "${CLIENTS[@]}"; do
    ./easyrsa --batch gen-req "$CLIENT" nopass
    ./easyrsa --batch sign-req client "$CLIENT"
done
