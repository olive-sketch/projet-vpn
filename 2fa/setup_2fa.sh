#!/bin/bash
set -euo pipefail

USERS=("user1" "user2")

apt-get update -y
apt-get install -y libpam-google-authenticator

cat > /etc/pam.d/openvpn <<'PAM'
auth    required   pam_google_authenticator.so nullok secret=/etc/openvpn/2fa/${USER}/.google_authenticator
account required   pam_unix.so
session required   pam_unix.so
PAM

for USER in "${USERS[@]}"; do
    if ! id "$USER" &>/dev/null; then
        useradd --system --no-create-home --shell /usr/sbin/nologin "$USER"
    fi

    SECRET_DIR="/etc/openvpn/2fa/$USER"
    mkdir -p "$SECRET_DIR"

    google-authenticator \
        --time-based \
        --disallow-reuse \
        --force \
        --rate-limit=3 \
        --rate-time=30 \
        --window-size=3 \
        --secret="$SECRET_DIR/.google_authenticator" \
        --qr-mode=UTF8 \
        --no-confirm

    chown -R "$USER:$USER" "$SECRET_DIR"
    chmod 700 "$SECRET_DIR"
    chmod 600 "$SECRET_DIR/.google_authenticator"
done
