# Homebridge Backup - Dokumentacja Infrastruktury

**Ostatnia aktualizacja:** 2026-01-29

## Spis treści
- [Architektura systemu](#architektura-systemu)
- [Przegląd infrastruktury](#przegląd-infrastruktury)
- [Synology NAS DS224+](#synology-nas-ds224)
- [Orange Pi Zero 2](#orange-pi-zero-2)
- [Raspberry Pi 5](#raspberry-pi-5)
- [Mac Mini](#mac-mini)
- [Cloudflare Tunnels](#cloudflare-tunnels)
- [Tailscale VPN](#tailscale-vpn)
- [Harmonogram backupów](#harmonogram-backupów)
- [Skrypty automatyzacji](#skrypty-automatyzacji)
- [Procedury przywracania](#procedury-przywracania)

---

## Architektura systemu

```
                          ┌─────────────────────────┐
                          │        INTERNET         │
                          └────────────┬────────────┘
                                       │
                          ┌────────────▼────────────┐
                          │    Cloudflare Tunnels   │
                          │     *.bodino.us.kg      │
                          └────────────┬────────────┘
                                       │
    ┌────────────────────────────────────┼──────────────────────────────────┐
    │                                    │                                  │
┌───▼──────────────────────┐  ┌──────────▼──────────┐  ┌────────────────────▼───┐
│    RASPBERRY PI 5        │  │  ORANGE PI ZERO 2   │  │       MAC MINI         │
│    192.168.0.188         │  │  192.168.0.133      │  │     192.168.0.106      │
│  TS: 100.112.174.109     │  │ TS: 100.90.85.113   │  ├────────────────────────┤
│    (główny serwer)       │  │   (backup DNS)      │  │ • Jellyfin:8096        │
├──────────────────────────┤  ├─────────────────────┤  │ • Time Machine         │
│ • Homebridge:8581        │  │ • Pi-hole:80        │  │                        │
│ • Zigbee2MQTT:8080       │  │ • Unbound:5335      │  │                        │
│ • Mosquitto:1883         │  │ • Tailscale subnet  │  │                        │
│ • n8n:5678               │  │   router 192.168.0/24│  │                        │
│ • Pi-hole:80             │  │                     │  │                        │
│ • Unbound:5335           │  │                     │  │                        │
│ • Home Assistant         │  │                     │  │                        │
│ • ClawdBot:3000          │  │                     │  │                        │
│ • MS365 MCP:3365         │  │                     │  │                        │
│ • Docker Watchdog        │  │                     │  │                        │
└─────────────┬────────────┘  └─────────────────────┘  └────────────────────────┘
              │
              │        SMB         ┌─────────────────────────┐
              ├────────────────────│    SYNOLOGY DS224+      │
              │                    │    192.168.0.164        │
              │                    │  TS: 100.106.39.80      │
              │                    ├─────────────────────────┤
              │                    │ • 2x18TB RAID1 (Btrfs)  │
              │                    │ • SMB: media, backups,  │
              │                    │   roms, timemachine     │
              │                    └─────────────────────────┘
              │
              │     ┌───────────────────────────┐
              │     │      Tailscale VPN        │
              └─────│      (mesh network)       │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │   Urządzenia mobilne      │
                    │   iPhone:  100.70.222.16  │
                    │   MacBook: 100.111.215.83 │
                    │   AppleTV: 100.85.3.71    │
                    └───────────────────────────┘

PRZEPŁYW DANYCH:
────────────────
Internet → Cloudflare → Urządzenie lokalne (HTTPS/SSH)
Urządzenia Zigbee → Zigbee2MQTT → Mosquitto → Homebridge → HomeKit
Apple TV → Cloudflare (jellyfin.bodino.us.kg) → Mac Mini (Jellyfin streaming)
Raspberry Pi ← SMB → NAS (ROMs, media, backups)
Mac Mini ← Time Machine → NAS
Telegram/iMessage → ClawdBot (RPi) → MS365 MCP → Microsoft Graph API
ClawdBot → BlueBubbles (Mac Mini) → iMessage
```

---

## Przegląd infrastruktury

| Urządzenie | IP Ethernet | IP WiFi | IP Tailscale | System | Rola |
|------------|-------------|---------|--------------|--------|------|
| Synology DS224+ | 192.168.0.164 | - | 100.106.39.80 | DSM 7 | NAS (storage, backups, Time Machine), qBittorrent |
| Bodino_NAS | 192.168.0.110 | - | - | - | Stary NAS (zdjęcia) |
| Orange Pi Zero 2 | 192.168.0.133 | 192.168.0.134 | 100.90.85.113 | Armbian 25.11.2 (Bookworm) | Pi-hole (backup DNS), Tailscale subnet router |
| Raspberry Pi 5 | 192.168.0.188 | - | 100.112.174.109 | Debian 13 (Trixie), NVMe SSD | Homebridge, Zigbee2MQTT, n8n, Pi-hole, Home Assistant |
| Mac Mini | 192.168.0.106 | - | - | macOS | Jellyfin |
| Apple TV | - | - | 100.85.3.71 | tvOS | Streaming Jellyfin |

---

## Synology NAS DS224+

### Dane dostępowe

| Parametr | Wartość |
|----------|---------|
| **Model** | Synology DS224+ |
| **IP** | 192.168.0.164 |
| **User** | Bodino |
| **Hasło** | Keram1qazXSW@ |
| **SSH** | Włączone (port 22) |
| **System** | DSM 7 |

### Specyfikacja

| Parametr | Wartość |
|----------|---------|
| **Dyski** | 2x 18TB (RAID 1) |
| **Pojemność użytkowa** | ~16 TB |
| **System plików** | Btrfs |
| **RAM** | 18 GB (1x2GB + 1x16GB) |

### Foldery współdzielone

| Nazwa | Ścieżka | Opis |
|-------|---------|------|
| media | /volume1/media | Biblioteka multimediów (Jellyfin) |
| backups | /volume1/backups | Kopie zapasowe |
| roms | /volume1/roms | ROMs dla RetroArch |
| timemachine | /volume1/timemachine | Time Machine dla Mac |

### Dostęp SSH

```bash
ssh Bodino@192.168.0.164
# Hasło: Keram1qazXSW@
```

### Komendy administracyjne

```bash
# Lista udostępnień
sudo /usr/syno/sbin/synoshare --enum LOCAL

# Dodaj udostępnienie
sudo /usr/syno/sbin/synoshare --add <name> <desc> <path> '' <rw_user> '' 1 0

# Status RAID
cat /proc/mdstat

# Użycie dysków
df -h /volume1
```

### Cloudflare Tunnel

**Tunnel ID:** `268f4074-6efc-4cfb-acd8-ae7be8041a0b`
**Credentials:** `/volume1/cloudflared/.cloudflared/268f4074-6efc-4cfb-acd8-ae7be8041a0b.json`
**Binary:** `/volume1/cloudflared/cloudflared`

```yaml
# /volume1/cloudflared/config.yml
tunnel: 268f4074-6efc-4cfb-acd8-ae7be8041a0b
credentials-file: /volume1/cloudflared/.cloudflared/268f4074-6efc-4cfb-acd8-ae7be8041a0b.json

ingress:
  - hostname: nas.bodino.us.kg
    service: https://localhost:5001
    originRequest:
      noTLSVerify: true
  - hostname: nas-ssh.bodino.us.kg
    service: ssh://localhost:22
  - service: http_status:404
```

**Uruchomienie tunelu:**
```bash
HOME=/volume1/cloudflared nohup /volume1/cloudflared/cloudflared tunnel --config /volume1/cloudflared/config.yml run > /volume1/cloudflared/tunnel.log 2>&1 &
```

### Uwagi

- **Time Machine**: Wymaga włączenia w DSM → Control Panel → File Services → SMB → Advanced → Enable Time Machine
- **Połączenie z RPi**: RPi ma osobną trasę routingu dla NAS (omija Tailscale subnet routing)
- **Cloudflare Tunnel**: Uruchamiany ręcznie (Synology nie ma systemd)

### Tailscale

**Binary:** `/volume1/tailscale/tailscale`, `/volume1/tailscale/tailscaled`
**State:** `/volume1/tailscale/state/tailscaled.state`
**Socket:** `/volume1/tailscale/tailscaled.sock`
**IP Tailscale:** `100.106.39.80`

**Uruchomienie:**
```bash
# Daemon
sudo /volume1/tailscale/tailscaled --state=/volume1/tailscale/state/tailscaled.state --socket=/volume1/tailscale/tailscaled.sock &

# Status
sudo /volume1/tailscale/tailscale --socket=/volume1/tailscale/tailscaled.sock status
```

---

## Bodino_NAS (stary NAS)

### Dane dostępowe

| Parametr | Wartość |
|----------|---------|
| **Hostname** | Bodino_NAS |
| **IP** | 192.168.0.110 |
| **User** | admin |
| **Hasło** | Keram23weSDXC |

### Uwagi

- Stary NAS używany głównie do przechowywania zdjęć
- Zdjęcia mają być zmigrowane na nowy Synology DS224+

---

## Orange Pi Zero 2

### Dane dostępowe

| Parametr | Wartość |
|----------|---------|
| **IP Ethernet (end0)** | 192.168.0.133 |
| **IP WiFi (wlan0)** | 192.168.0.134 |
| **WiFi SSID** | Bodino_LTE_2.4 |
| **WiFi MAC** | 2c:2c:78:fb:20:3d |
| **IP Tailscale** | 100.90.85.113 |
| **User** | root |
| **Hasło** | Keram1qazXSW@ |
| **System** | Armbian 25.11.2 bookworm (kernel 6.12.23) |

### Serwisy

| Serwis | Port | Opis |
|--------|------|------|
| Pi-hole | 80 | DNS ad-blocking (backup) |
| Unbound | 5335 | Rekursywny DNS |
| Cloudflared | - | Cloudflare tunnel |
| Tailscale | - | VPN mesh |

> **Uwaga:** Homebridge, Zigbee2MQTT i Mosquitto zostały przeniesione na Raspberry Pi w dniu 2025-12-13.

### Cloudflare Tunnel

**Tunnel ID:** `cd9b3d38-ccd1-4adf-a88f-f177df0bcb8d`
**Credentials:** `/root/.cloudflared/cd9b3d38-ccd1-4adf-a88f-f177df0bcb8d.json`

```yaml
# /etc/cloudflared/config.yml
tunnel: cd9b3d38-ccd1-4adf-a88f-f177df0bcb8d
credentials-file: /root/.cloudflared/cd9b3d38-ccd1-4adf-a88f-f177df0bcb8d.json

ingress:
  - hostname: pihole-orange.bodino.us.kg
    service: http://localhost:80
  - hostname: orange-ssh.bodino.us.kg
    service: tcp://localhost:22
  - service: http_status:404
```

### Unbound

**Config:** `/etc/unbound/unbound.conf.d/pi-hole.conf`

```conf
server:
    verbosity: 0
    interface: 127.0.0.1
    port: 5335
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    do-ip6: no
    prefer-ip6: no
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: no
    edns-buffer-size: 1232
    prefetch: yes
    num-threads: 1
    so-rcvbuf: 1m
    private-address: 192.168.0.0/16
    private-address: 169.254.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8
    private-address: fd00::/8
    private-address: fe80::/10
```

### Cron Jobs

| Kiedy | Co | Skrypt |
|-------|-----|--------|
| Co 6h | Aktualizacja Pi-hole gravity | `/usr/local/bin/update-pihole.sh` |
| Niedziela 3:00 | Aktualizacja systemu i serwisów | `/usr/local/bin/weekly-update.sh` |

### Klucze SSH (authorized_keys)

```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbxXEHfLMii5ldtjfBeZsJ9I8L+OuVdowq7NqmFyJtL0QQWeN6CkOSJlhdKRFfzeq4U3cMC0qjF4S47RPt85mu1g97GIL8KSK8kmjK2E5OCGI6CXaKP+tCYbOdHgdQWhwpWkJGYbHQjQJHC0PV9Knr4Y2jHzfNjI1dWSdph/woapx01g5gH203iZSgRyvyJjMexf+rfD9Nj0quGEY+dpuedtAJ1C1PekKhIukOXqrC/KAdUDNSpYf2yUg7et1ytyYI66tXCl8W8aYB0s++ZuLl5KAOboZc7ZFh8gq/BB7s+A+Yyqt2XotG4N6y9/ZqzyGRHn5Tqsxcf+MooXRhOohSoi9PuTzB85wk7C3TxPbP80RmPyUgXWy9/iSJEfgdPOmsBwEVXPIZS8yt0XAl2738weMu+zUNHqCSXJ2an0QeTmvgHHnBbuIz0vggrowxQNiTSxmIymB+J4ljgamhU6vI59mC8ET8ae31QXhkMPyeSIKh11RvlzEQMO+t2Svqgo0= marekbodynek@Mac-mini-Marek.local
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPct3X9adLcLmUHRdWaq0lwvsiGO3o7uR4iuC0/ChAP0 marek@mac
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7sAbFYGdVUWaNd12Zuj1BGD1X1nBRKL8ufN52E5bCG root@raspberrypi
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFbPQdvqjne28bG+vUOUZoUxRMTs2+r4mz5G4n7XQagX bodino@BodinoPi
```

---

## Raspberry Pi 5

### Dane dostępowe

| Parametr | Wartość |
|----------|---------|
| **IP Ethernet (eth0)** | 192.168.0.188 |
| **IP WiFi (wlan0)** | - (nieaktywne) |
| **Ethernet MAC** | 88:a2:9e:57:e8:b5 |
| **WiFi SSID** | Bodino_LTE_2.4 |
| **IP Tailscale** | 100.112.174.109 |
| **User** | bodino |
| **Hasło** | Keram1qazXSW@ |
| **System** | Debian 13 (Trixie), kernel 6.12.47 |
| **Boot** | NVMe SSD (Samsung 990 EVO Plus 2TB) |
| **Pi-hole hasło** | bodino44 |

### Serwisy

| Serwis | Port | Opis |
|--------|------|------|
| Homebridge | 8581 (UI), 51641 (HAP) | Smart home bridge |
| Zigbee2MQTT | 8080 | Most Zigbee-MQTT |
| Mosquitto | 1883 | MQTT broker |
| n8n | 5678 | Automatyzacja workflow |
| Pi-hole | 80 | DNS ad-blocking |
| Unbound | 5335 | Rekursywny DNS |
| Home Assistant | 8123 | Docker kontener |
| Docker Watchdog | - | Monitoring HA (co 15 min) |
| ClawdBot Gateway | 3000 | AI assistant (Telegram/iMessage) |
| MS365 MCP Server | 3365 | Microsoft 365 API |
| Cloudflared | - | Cloudflare tunnel |
| Tailscale | - | VPN mesh |

### Cloudflare Tunnel

**Tunnel ID:** `278a7b8a-8f20-4854-95f9-75ef20c332a2`
**Credentials:** `/home/bodino/.cloudflared/278a7b8a-8f20-4854-95f9-75ef20c332a2.json`

```yaml
# /etc/cloudflared/config.yml
tunnel: 278a7b8a-8f20-4854-95f9-75ef20c332a2
credentials-file: /home/bodino/.cloudflared/278a7b8a-8f20-4854-95f9-75ef20c332a2.json

ingress:
  - hostname: rpi-ssh.bodino.us.kg
    service: ssh://localhost:22
  - hostname: n8n.bodino.us.kg
    service: http://localhost:5678
  - hostname: pihole.bodino.us.kg
    service: http://localhost:80
  - hostname: homebridge.bodino.us.kg
    service: http://localhost:8581
  - hostname: zigbee.bodino.us.kg
    service: http://localhost:8080
  - hostname: ha.bodino.us.kg
    service: http://localhost:8123
  - service: http_status:404
```

### Homebridge

**Config:** `/var/lib/homebridge/config.json`

```json
{
    "bridge": {
        "name": "Homebridge Bodino",
        "username": "0E:39:36:5E:B7:15",
        "port": 51641,
        "pin": "100-00-100"
    },
    "platforms": [
        {
            "name": "Config",
            "port": 8581,
            "auth": "form",
            "platform": "config",
            "standalone": true
        },
        {
            "mqtt": {
                "base_topic": "zigbee2mqtt",
                "server": "mqtt://localhost:1883",
                "user": "mqtt",
                "password": "mqtt"
            },
            "platform": "zigbee2mqtt"
        },
        {
            "name": "eWeLink",
            "username": "bodinoo@interia.pl",
            "password": "bodino44",
            "platform": "eWeLink"
        }
    ]
}
```

### Zigbee2MQTT

**Config:** `/opt/zigbee2mqtt/data/configuration.yaml`

```yaml
frontend:
  enabled: true
  port: 8080
mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://localhost:1883
  user: mqtt
  password: mqtt
serial:
  port: /dev/ttyUSB0
advanced:
  log_level: debug
  network_key:
    - 219
    - 194
    - 126
    - 138
    - 138
    - 160
    - 109
    - 93
    - 7
    - 251
    - 120
    - 73
    - 211
    - 234
    - 115
    - 179
```

### n8n

**Config:** `/home/bodino/.n8n/config`

```json
{
    "encryptionKey": "9gk3a1bZUB2jOy3bbZXl0YiIqQdjaBTW"
}
```

**Systemd service:** `/etc/systemd/system/n8n.service`

```ini
[Unit]
Description=n8n - Workflow Automation
After=network.target

[Service]
Type=simple
User=bodino
WorkingDirectory=/home/bodino
Environment="N8N_HOST=0.0.0.0"
Environment="N8N_PORT=5678"
Environment="N8N_PROTOCOL=http"
Environment="WEBHOOK_URL=https://n8n.bodino.us.kg/"
ExecStart=/usr/bin/n8n start
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Unbound

**Config:** `/etc/unbound/unbound.conf.d/pi-hole.conf`

```conf
server:
    verbosity: 0
    interface: 127.0.0.1
    port: 5335
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    do-ip6: no
    prefer-ip6: no
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: no
    edns-buffer-size: 1232
    prefetch: yes
    num-threads: 1
    so-rcvbuf: 1m
    private-address: 192.168.0.0/16
    private-address: 169.254.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8
```

### ClawdBot Gateway

AI assistant dostępny przez Telegram i iMessage.

**Serwis:** `clawdbot-gateway.service` (systemd user)
**Port:** 3000
**Katalog:** `~/.clawdbot/`

**Kanały:**
- Telegram: @ClawdBot
- iMessage: bodinoo@interia.pl (przez BlueBubbles na Mac Mini)

**Konfiguracja:** `~/.clawdbot/config.yaml`

### MS365 MCP Server

Serwer Microsoft 365 API dla ClawdBot (Microsoft Graph).

**Konto:** marek.bodynek@kea.si
**Serwis:** `ms365-mcp.service` (systemd user)
**Port:** 3365

**Funkcje:**
- Mail (odczyt, wysyłanie)
- Kalendarz (odczyt, tworzenie, współdzielone kalendarze)
- OneDrive (pliki)
- Tasks (zadania)
- Contacts (kontakty)

**Pliki:**
- Token: `~/ms365-token.json`
- Refresh script: `~/ms365-refresh-token.sh`
- Serwis: `~/.config/systemd/user/ms365-mcp.service`

**Azure App Registration:**
- App ID: `ed4fe004-daae-4437-838a-c9d4ef07ec53`
- Tenant ID: `ebdccd1d-ae7a-40d8-b3b4-9ed033b2b100`

**Cron:** Token odświeżany co 45 min (`~/ms365-refresh-token.sh`)

**Komendy:**
```bash
systemctl --user status ms365-mcp        # Status serwisu
~/ms365-refresh-token.sh                  # Ręczne odświeżenie tokena
curl -s -H "Authorization: Bearer $(jq -r .access_token ~/ms365-token.json)" \
  "https://graph.microsoft.com/v1.0/me"  # Test API
```

### Cron Jobs

**Plik:** `/etc/cron.d/rpi-automation`

| Kiedy | Co | Skrypt |
|-------|-----|--------|
| Co 5 min | Sprawdzanie tuneli | `/usr/local/bin/check-tunnels.sh` |
| Co 6h | Aktualizacja Pi-hole gravity | `/usr/local/bin/update-pihole.sh` |
| Niedziela 3:00 | Aktualizacja systemu i serwisów | `/usr/local/bin/weekly-update.sh` |

### RetroArch + Emulatory

**ROMy:** Montowane z NAS przez SMB (`/mnt/roms`)

| Emulator | Platforma | Komenda |
|----------|-----------|---------|
| RetroArch | Multi-platform | `retroarch` |
| Duckstation | PlayStation 1 | `duckstation` |
| Dolphin | GameCube/Wii | `dolphin-emu` |
| MAME | Arcade | `mame` |
| Mednafen | NES/GB/PCE/Lynx | `mednafen` |
| VICE | C64/128/VIC20 | `x64sc` |
| FS-UAE | Amiga | `fs-uae` |
| Hatari | Atari ST | `hatari` |
| Stella | Atari 2600 | `stella` |
| Atari800 | Atari 800/XL/XE/5200 | `atari800` |
| Fuse | ZX Spectrum | `fuse` |
| DOSBox | DOS | `dosbox` |
| Osmose | Master System/Game Gear | `osmose` |
| PCSXR | PlayStation 1 | `pcsxr` |

**SMB Mount:** `/etc/fstab`
```
//192.168.0.164/roms /mnt/roms cifs credentials=/etc/smb-credentials-nas,uid=1000,gid=1000,iocharset=utf8,vers=3.0,nofail 0 0
```

**Credentials:** `/etc/smb-credentials-nas` (chmod 600)
```
username=Bodino
password=Keram1qazXSW@
```

### NAS Route Fix (Tailscale)

Orange Pi reklamuje podsieć 192.168.0.0/24 przez Tailscale, co powoduje że ruch do NAS idzie przez tunel.
Rozwiązanie: systemd service który usuwa tę trasę i dodaje bezpośrednią trasę do NAS.

**Service:** `/etc/systemd/system/nas-route.service`
```ini
[Unit]
Description=Fix NAS route for Tailscale
After=network-online.target tailscaled.service

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 10
ExecStart=/bin/bash -c 'ip route del 192.168.0.0/24 dev tailscale0 table 52 2>/dev/null; ip route add 192.168.0.164/32 dev eth0 src 192.168.0.188 2>/dev/null || true'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

### Docker Watchdog

**Script:** `/usr/local/bin/docker-watchdog.sh`
**Cron:** `*/15 * * * *`

Sprawdza co 15 minut:
1. Czy Docker daemon działa
2. Czy kontener homeassistant jest uruchomiony
3. Czy HA odpowiada na port 8123

**Logi:** `/var/log/docker-watchdog.log`

### Klucze SSH (authorized_keys)

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPct3X9adLcLmUHRdWaq0lwvsiGO3o7uR4iuC0/ChAP0 marek@mac
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbxXEHfLMii5ldtjfBeZsJ9I8L+OuVdowq7NqmFyJtL0QQWeN6CkOSJlhdKRFfzeq4U3cMC0qjF4S47RPt85mu1g97GIL8KSK8kmjK2E5OCGI6CXaKP+tCYbOdHgdQWhwpWkJGYbHQjQJHC0PV9Knr4Y2jHzfNjI1dWSdph/woapx01g5gH203iZSgRyvyJjMexf+rfD9Nj0quGEY+dpuedtAJ1C1PekKhIukOXqrC/KAdUDNSpYf2yUg7et1ytyYI66tXCl8W8aYB0s++ZuLl5KAOboZc7ZFh8gq/BB7s+A+Yyqt2XotG4N6y9/ZqzyGRHn5Tqsxcf+MooXRhOohSoi9PuTzB85wk7C3TxPbP80RmPyUgXWy9/iSJEfgdPOmsBwEVXPIZS8yt0XAl2738weMu+zUNHqCSXJ2an0QeTmvgHHnBbuIz0vggrowxQNiTSxmIymB+J4ljgamhU6vI59mC8ET8ae31QXhkMPyeSIKh11RvlzEQMO+t2Svqgo0= marekbodynek@Mac-mini-Marek.local
```

---

## Mac Mini

### Dane dostępowe

| Parametr | Wartość |
|----------|---------|
| **IP lokalne** | 192.168.0.106 |
| **User** | marekbodynek |
| **Hasło** | Keram1qazXSW@3edcV |
| **System** | macOS |

### Serwisy

| Serwis | Port | Opis |
|--------|------|------|
| Jellyfin | 8096 | Media server |
| BlueBubbles | 1234 | iMessage bridge server |
| Time Machine | - | Backup na NAS (//192.168.0.164/timemachine) |
| Cloudflared | - | Cloudflare tunnel |

> **Uwaga:** Docker został usunięty z Mac Mini. Home Assistant przeniesiony na RPi (2025-12-14).

### Cloudflare Tunnel

**Tunnel ID:** `877197db-185e-43e9-983b-0fd95bd422ba`
**Credentials:** `/Users/marekbodynek/.cloudflared/877197db-185e-43e9-983b-0fd95bd422ba.json`

```yaml
# ~/.cloudflared/config.yml
tunnel: 877197db-185e-43e9-983b-0fd95bd422ba
credentials-file: /Users/marekbodynek/.cloudflared/877197db-185e-43e9-983b-0fd95bd422ba.json

ingress:
  - hostname: jellyfin.bodino.us.kg
    service: http://localhost:8096
  - hostname: macmini-ssh.bodino.us.kg
    service: ssh://localhost:22
  - hostname: bluebubbles.bodino.us.kg
    service: http://localhost:1234
  - service: http_status:404
```

### BlueBubbles (iMessage Bridge)

**URL:** `https://bluebubbles.bodino.us.kg`
**Password:** `Keram1qazXSW@`
**iMessage:** `bodinoo@interia.pl`
**Port lokalny:** 1234

**Funkcje:**
- Wysyłanie/odbieranie iMessage przez API
- Integracja z ClawdBot (Telegram → iMessage)
- Auto-start jako LaunchAgent

**Konfiguracja:**
- App: `/Applications/BlueBubbles.app`
- Full Disk Access: włączony
- Accessibility: włączony
- Private API: wyłączony (SIP aktywny)

### Cron Jobs

| Kiedy | Co | Skrypt |
|-------|-----|--------|
| Co 5 min | Watchdog cloudflared | `/usr/local/bin/cloudflared-watchdog.sh` |
| Codziennie 1:00 | Backup konfiguracji serwisów | `/Users/marekbodynek/scripts/backup-services.sh` |
| Niedziela 2:00 | Pełny backup obrazów systemów | `/Users/marekbodynek/scripts/backup-servers.sh` |

### Lokalizacja backupów

**Dysk:** Seagate25_5T (5 TB)
**Ścieżka:** `/Volumes/Seagate25_5T/.backups/`

| Folder | Zawartość | Retencja |
|--------|-----------|----------|
| `/` | Pełne obrazy dd (RPi, OPi) | 2 kopie |
| `/services/` | Konfiguracje serwisów | 7 dni |

---

## MacBook Pro

### Dane dostępowe

| Parametr | Wartość |
|----------|---------|
| **Model** | MacBook Pro 18,3 (M1 Pro) |
| **User** | marekbodynek |
| **Hasło** | bodino44 |
| **IP Tailscale** | 100.111.215.83 |

### VPN Menu (SwiftBar)

Menu w pasku systemowym do zarządzania połączeniami VPN.

**Uruchomienie:** `open -a SwiftBar`

| VPN | Opis | Połączenie | Rozłączenie |
|-----|------|------------|-------------|
| **KEA** | OpenVPN do sieci firmowej KEA | `openvpn --config ~/.openvpn/KEAMarekB.ovpn` | kill openvpn |
| **DOM** | Tailscale do sieci domowej | `tailscale up` | `tailscale down` |
| **STU** | Checkpoint VPN (Studenac) | AppleScript (keystroke hasło) + Chrome | `trac disconnect` |
| **NORD** | NordVPN Poland | AppleScript (auto-connect Poland) | AppleScript |

**Ikona w pasku:**
- `VPN` (biały) - wszystkie rozłączone
- `VPN: KEA DOM` (zielony) - pokazuje aktywne VPN-y

**Pliki konfiguracyjne:**
- Plugin: `~/Library/Application Support/SwiftBar/Plugins/vpn-all.30s.sh`
- OpenVPN config: `~/.openvpn/KEAMarekB.ovpn`
- Skrypty VPN:
  - `~/scripts/vpn-kea-start.sh` / `vpn-kea-stop.sh`
  - `~/scripts/vpn-stu-connect.applescript` / `vpn-stu-disconnect.sh`
  - `~/scripts/vpn-nord-connect.sh` / `vpn-nord-disconnect.sh`

**STU VPN (Checkpoint) - szczegóły:**
- Połączenie: Zamyka i otwiera aplikację, wpisuje hasło przez keystroke, czeka na połączenie (max 60s), otwiera Chrome z URL Qlik Sense i loguje
- Rozłączenie: `trac disconnect` + `killall "Endpoint Security VPN"`
- Hasło: `Keram6yhnMJU&`
- User: `marek.bodynek`

**Aliasy terminala:**
```bash
vpn-on   # Połącz KEA
vpn-off  # Rozłącz KEA
vpn      # Status KEA
```

### USB Hub Sleep Guard

Daemon blokujący usypianie gdy podłączony jest hub USB (zapobiega kernel panic po wybudzeniu).

**Monitorowane huby:**

| Hub | VID:PID | Lokalizacja |
|-----|---------|-------------|
| Ugreen CM512 | 1507:1574 | Praca |
| Ugreen CM818 | 1507:1573 | Praca |
| Ugreen CM512 (dom) | 1507:1552 | Dom |

**Pliki:**
- Daemon: `~/scripts/usb-hub-sleep-daemon.sh`
- LaunchAgent: `~/Library/LaunchAgents/com.bodino.usb-hub-sleep-guard.plist`
- Log: `~/scripts/usb-hub-sleep-guard.log`

**Działanie:**
- Sprawdza co 5 sekund czy hub jest podłączony (przez ioreg VID/PID)
- Jeśli tak → uruchamia `caffeinate -s` (blokuje usypianie)
- Jeśli nie → zatrzymuje caffeinate

---

## Cloudflare Tunnels

### Podsumowanie tuneli

| Tunel | Urządzenie | Tunnel ID | Hostname |
|-------|------------|-----------|----------|
| orangepi | Orange Pi | cd9b3d38-ccd1-4adf-a88f-f177df0bcb8d | pihole-orange, orange-ssh |
| raspberry-pi | Raspberry Pi | 278a7b8a-8f20-4854-95f9-75ef20c332a2 | rpi-ssh, n8n, pihole, homebridge, zigbee, ha |
| macmini-tunnel-new | Mac Mini | 877197db-185e-43e9-983b-0fd95bd422ba | jellyfin, macmini-ssh |
| nas-tunnel | Synology NAS | 268f4074-6efc-4cfb-acd8-ae7be8041a0b | nas, nas-ssh |

### Dostępne endpointy

| URL | Serwis | Urządzenie |
|-----|--------|------------|
| https://ha.bodino.us.kg | Home Assistant | Raspberry Pi |
| https://homebridge.bodino.us.kg | Homebridge UI | Raspberry Pi |
| https://zigbee.bodino.us.kg | Zigbee2MQTT | Raspberry Pi |
| https://n8n.bodino.us.kg | n8n | Raspberry Pi |
| https://pihole.bodino.us.kg | Pi-hole (RPi) | Raspberry Pi |
| https://pihole-orange.bodino.us.kg | Pi-hole (Orange) | Orange Pi |
| https://jellyfin.bodino.us.kg | Jellyfin | Mac Mini |
| https://nas.bodino.us.kg | DSM Panel | Synology NAS |

### SSH przez Cloudflare

Dodaj do `~/.ssh/config`:

```
Host orange-ssh.bodino.us.kg
    ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h

Host rpi-ssh.bodino.us.kg
    ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h

Host macmini-ssh.bodino.us.kg
    ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h

Host nas-ssh.bodino.us.kg
    ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h
```

---

## Tailscale VPN

### Urządzenia w sieci

| Urządzenie | Tailscale IP | Tailscale SSH | Status |
|------------|--------------|---------------|--------|
| Synology NAS | 100.106.39.80 | - | online |
| Orange Pi | 100.90.85.113 | ✓ | online |
| Raspberry Pi | 100.112.174.109 | ✓ | online |
| MacBook Pro | 100.111.215.83 | - | online |
| Apple TV | 100.85.3.71 | - | online |
| iPhone | 100.70.222.16 | - | online |

### Instalacja Tailscale

**macOS:**
```bash
brew install --cask tailscale
```

**Debian/Armbian:**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

**Apple TV:**
App Store → Tailscale

### Port forwarding (router)

```
UDP 41641 → 192.168.0.106:41641 (Mac Mini - bezpośrednie połączenie)
```

---

## Harmonogram backupów

### Synology NAS DS224+ (centralne backupy)

Wszystkie backupy zapisywane są na NAS1 w `/volume1/backups/`.

| Urządzenie | Kiedy | Lokalizacja na NAS | Retencja |
|------------|-------|-------------------|----------|
| Raspberry Pi | Niedziela 3:00 | `/volume1/backups/rpi/` | 30 dni |
| Orange Pi | Niedziela 3:00 | `/volume1/backups/opi/` | 30 dni |

### Mac Mini

Mac Mini używa **Time Machine** do backupów na NAS (`//192.168.0.164/timemachine`).

---

## Skrypty automatyzacji

### check-tunnels.sh (Raspberry Pi)

**Lokalizacja:** `/usr/local/bin/check-tunnels.sh`
**Cron:** `*/5 * * * *`

Sprawdza status tuneli Cloudflare na wszystkich urządzeniach i restartuje w razie awarii.

### update-pihole.sh (Orange Pi / Raspberry Pi)

**Lokalizacja:** `/usr/local/bin/update-pihole.sh`
**Cron:** `0 */6 * * *`

Aktualizuje listy blokujące Pi-hole (gravity).

### weekly-update.sh (Orange Pi / Raspberry Pi)

**Lokalizacja:** `/usr/local/bin/weekly-update.sh`
**Cron:** `0 3 * * 0` (niedziela 3:00)

1. Tworzy backup konfiguracji
2. Aktualizuje pakiety systemowe
3. Aktualizuje serwisy (Homebridge, Zigbee2MQTT, n8n, Pi-hole)
4. Restartuje wszystkie serwisy

---

## Procedury przywracania

### Przywracanie Orange Pi

1. **Instalacja od zera:**
   - Flash Armbian Bookworm na kartę SD
   - Ustaw IP statyczne: 192.168.0.133
   - Zainstaluj serwisy w kolejności:
     1. Pi-hole + Unbound
     2. Cloudflared
     3. Tailscale

2. **Przywróć konfiguracje z backupu (NAS1):**
   ```bash
   # Zamontuj NAS1
   mount -t cifs //192.168.0.164/backups /mnt/backups -o user=Bodino
   tar -xzf /mnt/backups/opi/backup-YYYY-MM-DD.tar.gz -C /
   ```

### Przywracanie Raspberry Pi

1. **Instalacja od zera:**
   - Flash Raspberry Pi OS (Lite 64-bit)
   - Ustaw IP statyczne: 192.168.0.188
   - User: bodino, hasło: Keram1qazXSW@
   - Zainstaluj serwisy:
     1. Pi-hole + Unbound
     2. Node.js 22 + n8n
     3. Homebridge
     4. Zigbee2MQTT + Mosquitto
     5. Docker + Home Assistant
     6. Cloudflared
     7. Tailscale

2. **Przywróć konfiguracje z backupu (NAS1):**
   ```bash
   # Zamontuj NAS1
   mount -t cifs //192.168.0.164/backups /mnt/backups -o user=Bodino
   tar -xzf /mnt/backups/rpi/backup-YYYY-MM-DD.tar.gz -C /
   ```

### Przywracanie Cloudflare Tunnel

1. **Zaloguj do Cloudflare:**
   ```bash
   cloudflared tunnel login
   ```

2. **Użyj istniejącego tunelu:**
   ```bash
   # Skopiuj credentials file z backupu do ~/.cloudflared/
   # Skopiuj config.yml do /etc/cloudflared/

   sudo systemctl enable cloudflared
   sudo systemctl start cloudflared
   ```

3. **Lub utwórz nowy tunel:**
   ```bash
   cloudflared tunnel create <nazwa>
   # Zaktualizuj DNS w Cloudflare dashboard
   ```

---

## Bezpieczeństwo

### Fail2ban (Orange Pi + Raspberry Pi)

**Config:** `/etc/fail2ban/jail.local`

```ini
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8 192.168.0.0/24 100.64.0.0/10

[sshd]
enabled = true
maxretry = 3
bantime = 24h
```

**Komendy:**
```bash
fail2ban-client status sshd     # Status jail SSH
fail2ban-client unban <IP>      # Odblokuj IP
```

### CrowdSec (Raspberry Pi)

Kolaboracyjny IDS/IPS z firewall bouncer.

**Komendy:**
```bash
sudo cscli metrics              # Metryki
sudo cscli decisions list       # Lista zablokowanych IP
sudo cscli bouncers list        # Status bouncerów
```

**Instalowane scenariusze:**
- ssh-bf (brute-force SSH)
- ssh-slow-bf (wolny brute-force)
- ssh-cve-2024-6387 (wykrywanie exploita)

### Automatyczne aktualizacje bezpieczeństwa (unattended-upgrades)

Zainstalowane na obu urządzeniach. Automatycznie instaluje tylko krytyczne aktualizacje bezpieczeństwa.

**Config:** `/etc/apt/apt.conf.d/50unattended-upgrades`

- Tylko pakiety z etykietą `Debian-Security`
- Timer: codziennie ~6:00 (nie koliduje z tygodniowymi aktualizacjami o 3:00)
- Nie wymaga restartu (kernel updates wymagają ręcznego restartu)

**Komendy:**
```bash
unattended-upgrades --dry-run     # Symulacja
cat /var/log/unattended-upgrades/unattended-upgrades.log  # Logi
```

### Logwatch (monitoring logów)

Zainstalowane na obu urządzeniach. Generuje codzienne raporty z logów systemowych.

**Config:** `/etc/logwatch/conf/logwatch.conf`
**Raporty:** `/var/log/logwatch/logwatch.log`

- Timer: codziennie (cron.daily)
- Detail: Medium
- Zakres: wczorajsze logi

**Komendy:**
```bash
logwatch --output stdout --range today --detail Med   # Ręczny raport
cat /var/log/logwatch/logwatch.log                    # Ostatni raport
```

### Pi-hole - Listy bezpieczeństwa

Dodatkowe listy blokujące malware i phishing:

| Lista | Opis |
|-------|------|
| URLhaus | Malware URLs |
| Phishing Filter | Strony phishingowe |
| Anti-Malware | Złośliwe domeny |
| Risk Hosts | Ryzykowne hosty |
| Spam404 | Spam i scam |
| Prigent-Crypto | Koparki kryptowalut |
| The Great Wall | Chińskie złośliwe domeny |

**Statystyki blokowania:**
- Orange Pi: ~2,022,200 domen
- Raspberry Pi: ~2,071,191 domen

---

## Historia zmian

### 2026-01-29
- **BlueBubbles na Mac Mini**
  - Zainstalowano BlueBubbles (iMessage bridge server)
  - URL: https://bluebubbles.bodino.us.kg
  - Cloudflare Tunnel: dodano routing bluebubbles.bodino.us.kg → localhost:1234
  - Integracja z ClawdBot: plugin bluebubbles włączony
  - iMessage: bodinoo@interia.pl
- **ClawdBot - kanał BlueBubbles**
  - Włączono plugin bluebubbles
  - Konfiguracja: serverUrl + password
  - Telegram + iMessage działają równolegle
- **MS365 MCP Server na RPi**
  - Zintegrowano Microsoft 365 z ClawdBot
  - Azure App Registration: ClawdBot MS365
  - Konto: marek.bodynek@kea.si
  - Funkcje: Mail, Calendar (+ współdzielone), OneDrive, Tasks, Contacts
  - Uprawnienia: Calendars.Read.Shared, Calendars.ReadWrite.Shared
  - Serwis systemd user: ms365-mcp.service (port 3365)
  - Auto-refresh tokena co 45 min (cron)

### 2026-01-28
- **VPN Menu dla MacBook Pro**
  - Zainstalowano SwiftBar (zamiennik xbar - stabilniejszy)
  - Plugin: `vpn-all.30s.sh` - zarządzanie 4 VPN-ami
  - KEA (OpenVPN), DOM (Tailscale), STU (Checkpoint), NORD (NordVPN)
  - STU: pełna automatyzacja - łączy VPN, otwiera Chrome, loguje na Qlik Sense
  - Detekcja statusu: pgrep (KEA), tailscale status (DOM), trac info (STU), defaults read (NORD)
- **USB Hub Sleep Guard - trzeci hub**
  - Dodano Ugreen CM512 (dom) - VID:1507, PID:1552
  - Daemon monitoruje teraz 3 huby

### 2025-12-22
- **Cloudflare Tunnel dla Synology NAS**
  - Zainstalowano cloudflared na NAS
  - Tunnel ID: 268f4074-6efc-4cfb-acd8-ae7be8041a0b
  - Dostęp do DSM: https://nas.bodino.us.kg
  - SSH przez Cloudflare: nas-ssh.bodino.us.kg
- **SMB dla RPi SSD**
  - Skonfigurowano Sambę na RPi
  - Udział [ssd] udostępnia /home/bodino
  - Dostęp: smb://192.168.0.188/ssd (user: bodino)
- **RetroArch na RPi**
  - Skonfigurowano profil DualSense PS5
  - Naprawiono mapowanie kontrolera
  - Ustawiono domyślny katalog na /mnt/roms
- **Tailscale na Synology NAS**
  - Zainstalowano Tailscale v1.92.3
  - IP Tailscale: 100.106.39.80
  - Hostname: bodinonas1

### 2025-12-19
- **Konfiguracja NAS Synology DS224+**
  - 2x 18TB RAID 1 (Btrfs), 18GB RAM
  - Utworzono foldery współdzielone: media, backups, roms, timemachine
  - Skonfigurowano SSH (user: Bodino)
- **Migracja systemu RPi na NVMe SSD**
  - Samsung 990 EVO Plus 2TB
  - Boot order: NVMe → SD → USB
  - System przeniesiony z karty SD (~20GB)
- **Zmiana źródła ROMs dla RetroArch**
  - Z Mac Mini (192.168.0.106) na NAS (192.168.0.164)
  - Nowy plik credentials: /etc/smb-credentials-nas
  - Dodany nas-route.service (fix dla Tailscale subnet routing)
- **Docker Watchdog na RPi**
  - Monitoring Home Assistant co 15 minut
  - Sprawdza: Docker daemon, kontener HA, HTTP health
  - Logi: /var/log/docker-watchdog.log
- **Usunięto Docker z Mac Mini**
  - Wszystkie kontenery i obrazy usunięte
  - Mac Mini teraz tylko: Jellyfin + Time Machine

### 2025-12-14
- **Migracja Home Assistant z Mac Mini na Raspberry Pi**
  - Zainstalowano Docker na RPi
  - Przeniesiono konfigurację HA (~926MB) z Mac Mini
  - HA uruchomiony w kontenerze Docker na RPi (port 8123)
  - Zaktualizowano DNS route ha.bodino.us.kg → tunel RPi
  - Usunięto zbędne kontenery z Mac Mini (n8n, cloudflared, n8n-mcp)
- Mac Mini teraz tylko: Jellyfin + Backupy (HA zatrzymany, nie usunięty)

### 2025-12-13
- **Migracja smart home z Orange Pi na Raspberry Pi**
  - Przeniesiono: Homebridge, Zigbee2MQTT, Mosquitto
  - Zaktualizowano Cloudflare Tunnel routes
  - Zaktualizowano skrypty weekly-update.sh na obu urządzeniach
- Orange Pi teraz pełni rolę backup DNS (tylko Pi-hole + Unbound)
- **Naprawiono problem z routingiem Tailscale na RPi**
  - Tailscale przejmował routing dla adresów lokalnych (192.168.0.x)
  - Rozwiązanie: `ip rule add from 192.168.0.188 lookup main priority 5200`
  - Zmiana trwała w `/etc/crontab` (@reboot)
- Zaktualizowano IP Raspberry Pi: 192.168.0.188 (Ethernet, nie WiFi)

### 2025-12-12
- Instalacja RetroArch + emulatorów na Raspberry Pi
- Konfiguracja SMB mount dla ROMów z Mac Mini
- Zainstalowane: RetroArch, Duckstation, Dolphin, MAME, Mednafen, VICE, FS-UAE, Hatari, Stella, Fuse, DOSBox, Osmose, PCSXR

### 2025-12-11
- Pełne przywracanie Raspberry Pi po awarii karty SD
- Konfiguracja codziennych backupów konfiguracji serwisów
- Konfiguracja tygodniowych backupów obrazów systemów (dd)
- Wdrożenie Fail2ban na obu urządzeniach
- Wdrożenie CrowdSec na Raspberry Pi
- Dodanie list bezpieczeństwa do Pi-hole (malware, phishing, crypto miners)
- Wdrożenie unattended-upgrades (automatyczne aktualizacje bezpieczeństwa)
- Wdrożenie Logwatch (monitoring logów)
- Aktualizacja dokumentacji

### 2025-12-09
- Tailscale bezpośrednio na Mac Mini
- Instalacja Jellyfin na Mac Mini
- Streaming przez Tailscale + Jellyfin

### 2025-12-05
- Pełna reinstalacja Orange Pi po awarii karty SD
- Upgrade do Debian 13 (Trixie)

---

## Notatki

- **Kolejność łączenia SSH**:
  - **W sieci Bodino_LTE_2.4** (192.168.0.x) → najpierw **lokalnie**: `ssh bodino@192.168.0.188`
  - **Poza siecią domową** → kolejność:
    1. **Cloudflare Tunnel**: `ssh -o ProxyCommand="cloudflared access ssh --hostname %h" bodino@rpi-ssh.bodino.us.kg`
    2. **Tailscale**: `ssh bodino@100.112.174.109`
- **HomeKit jest głównym źródłem kontroli temperatury** - harmonogramy Zigbee wyłączone
- **Pi-hole blokuje ~2M domen** - Firebog + polskie listy, aktualizowane co 6h
- **Frontend Zigbee2MQTT** bez zabezpieczenia hasłem (próba dodania auth zakończyła się błędem YAML)
- **Backupy n8n** mogą być duże (~1 GB) - przechowywane tylko na Mac Mini
