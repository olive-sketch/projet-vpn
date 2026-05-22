#!/bin/bash
set -euo pipefail

EASYRSA_DIR="/etc/easy-rsa"
OUTPUT_DIR="/etc/openvpn/clients"
SERVER_IP="<VOTRE_IP_SERVEUR>"
SERVER_PORT="1194"
CLIENTS=("user1" "user2")

mkdir -p "$OUTPUT_DIR"

CA=$(cat "$EASYRSA_DIR/pki/ca.crt")
TA=$(cat "$EASYRSA_DIR/pki/ta.key")

for CLIENT in "${CLIENTS[@]}"; do
    CERT=$(cat "$EASYRSA_DIR/pki/issued/${CLIENT}.crt")
    KEY=$(cat "$EASYRSA_DIR/pki/private/${CLIENT}.key")

    cat > "$OUTPUT_DIR/${CLIENT}.ovpn" <<OVPN
client
dev tun
proto udp
remote $SERVER_IP $SERVER_PORT

resolv-retry infinite
nobind
persist-key
persist-tun

remote-cert-tls server
verify-x509-name server name

cipher AES-256-GCM
auth SHA256
tls-version-min 1.2
tls-cipher TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384

auth-user-pass
key-direction 1
verb 3

<ca>
$CA
</ca>

<cert>
$CERT
</cert>

<key>
$KEY
</key>

<tls-auth>
$TA
</tls-auth>
OVPN

    chmod 600 "$OUTPUT_DIR/${CLIENT}.ovpn"
done
