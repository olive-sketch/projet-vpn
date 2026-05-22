# Projet VPN — OpenVPN sur Debian

Infrastructure VPN sécurisée avec OpenVPN, certificats PKI (Easy-RSA), firewall iptables et authentification à deux facteurs (Google Authenticator TOTP).

---

## Structure du dépôt

```
vpn-project/
├── server/
│   └── server.conf
├── scripts/
│   ├── setup_pki.sh
│   └── create_client_configs.sh
├── 2fa/
│   └── setup_2fa.sh
└── README.md
```

---

## Partie 1 — Installation et PKI

### Génération de la PKI et des certificats

```bash
sudo bash scripts/setup_pki.sh
```

### Génération des fichiers clients `.ovpn`

```bash
sudo bash scripts/create_client_configs.sh
```

### Déploiement de la configuration serveur

```bash
sudo cp server/server.conf /etc/openvpn/server/server.conf
```

### Chiffrement utilisé

| Paramètre | Valeur |
|-----------|--------|
| Cipher | AES-256-GCM |
| Auth HMAC | SHA-256 |
| TLS minimum | 1.2 |
| TLS cipher | ECDHE-RSA-AES256-GCM-SHA384 |
| Clé CA | RSA 4096 bits |

---

## Partie 2 — Systemd + Firewall

### Démarrage automatique

```bash
sudo mkdir -p /etc/systemd/system/openvpn-server@server.service.d/
sudo cp systemd/override.conf /etc/systemd/system/openvpn-server@server.service.d/
sudo systemctl daemon-reload
sudo systemctl enable --now openvpn-server@server
```

### Firewall

```bash
sudo bash firewall/firewall.sh
```

Les clients VPN (`10.8.0.0/24`) sont limités au trafic HTTP (port 80) uniquement.

---

## Partie 3 — Authentification à deux facteurs (2FA)

```bash
sudo bash 2fa/setup_2fa.sh
```

### Flux d'authentification

```
Client
  ├── 1. Certificat TLS      ← fichier .ovpn
  ├── 2. Username            ← saisie manuelle
  └── 3. Code TOTP           ← application Google Authenticator
          │
          ▼
       Serveur OpenVPN → PAM → google-authenticator → ACCÈS ACCORDÉ
```

---

## Ordre de déploiement

```bash
sudo bash scripts/setup_pki.sh
sudo bash scripts/create_client_configs.sh
sudo cp server/server.conf /etc/openvpn/server/server.conf
sudo bash 2fa/setup_2fa.sh
sudo mkdir -p /etc/systemd/system/openvpn-server@server.service.d/
sudo cp systemd/override.conf /etc/systemd/system/openvpn-server@server.service.d/
sudo systemctl daemon-reload
sudo systemctl enable --now openvpn-server@server
sudo bash firewall/firewall.sh
```
