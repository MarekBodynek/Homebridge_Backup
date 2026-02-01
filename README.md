# Homebridge Backup - Dokumentacja Infrastruktury

**Ostatnia aktualizacja:** 2026-02-01

> **Credentials:** Wszystkie hasła, klucze i tokeny znajdują się w `credentials.md` (nie w git)
>
> **Szczegóły:** Szczegółowa dokumentacja wyeksportowana do ByteRover

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
    ┌────────────────────────────────────┼──────────────────────────┐
    │                                    │                          │
┌───▼──────────────────────┐  ┌──────────▼──────────┐  ┌────────────▼───────────┐
│    RASPBERRY PI 5        │  │  ORANGE PI ZERO 2   │  │       MAC MINI         │
│    192.168.0.188         │  │  192.168.0.133      │  │     192.168.0.106      │
│  TS: 100.112.174.109     │  │ TS: 100.90.85.113   │  ├────────────────────────┤
│    (główny serwer)       │  │   (backup DNS)      │  │ • Jellyfin:8096        │
├──────────────────────────┤  ├─────────────────────┤  │ • BlueBubbles:1234     │
│ • Homebridge:8581        │  │ • Pi-hole:80        │  │ • Time Machine         │
│ • Zigbee2MQTT:8080       │  │ • Unbound:5335      │  │                        │
│ • Mosquitto:1883         │  │ • Tailscale subnet  │  │                        │
│ • n8n:5678               │  │ router 192.168.0/24 │  │                        │
│ • Pi-hole:80             │  │                     │  │                        │
│ • Unbound:5335           │  │                     │  │                        │
│ • Home Assistant:8123    │  │                     │  │                        │
│ • ClawdBot:3000          │  │                     │  │                        │
│ • MS365 MCP:3365         │  │                     │  │                        │
└─────────────┬────────────┘  └─────────────────────┘  └────────────────────────┘
              │
              │        SMB    ┌─────────────────────────┐
              ├────────────── │    SYNOLOGY DS224+      │
              │               │    192.168.0.164        │
              │               │  TS: 100.106.39.80      │
              │               ├─────────────────────────┤
              │               │ • 2x18TB RAID1 (Btrfs)  │
              │               │ • SMB: media, backups,  │
              │               │   roms, timemachine     │
              │               └─────────────────────────┘
              │
              │               ┌───────────────────────────┐
              │               │      Tailscale VPN        │
              └────────────── │      (mesh network)       │
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

| Urządzenie | IP Ethernet | IP Tailscale | Rola |
|------------|-------------|--------------|------|
| Synology DS224+ | 192.168.0.164 | 100.106.39.80 | NAS (storage, backups, Time Machine) |
| Orange Pi Zero 2 | 192.168.0.133 | 100.90.85.113 | Pi-hole (backup DNS), Tailscale subnet router |
| Raspberry Pi 5 | 192.168.0.188 | 100.112.174.109 | Homebridge, Zigbee2MQTT, n8n, Pi-hole, Home Assistant, ClawdBot |
| Mac Mini | 192.168.0.106 | - | Jellyfin, BlueBubbles |
| MacBook Pro | WiFi | 100.111.215.83 | Komputer roboczy |

---

## Dostępne serwisy (przez Cloudflare)

| URL | Serwis | Urządzenie |
|-----|--------|------------|
| https://ha.bodino.us.kg | Home Assistant | Raspberry Pi |
| https://homebridge.bodino.us.kg | Homebridge UI | Raspberry Pi |
| https://zigbee.bodino.us.kg | Zigbee2MQTT | Raspberry Pi |
| https://n8n.bodino.us.kg | n8n | Raspberry Pi |
| https://pihole.bodino.us.kg | Pi-hole (RPi) | Raspberry Pi |
| https://pihole-orange.bodino.us.kg | Pi-hole (OPi) | Orange Pi |
| https://jellyfin.bodino.us.kg | Jellyfin | Mac Mini |
| https://bluebubbles.bodino.us.kg | BlueBubbles | Mac Mini |
| https://nas.bodino.us.kg | DSM Panel | Synology NAS |

---

## Podstawowe komendy

### SSH - dostęp lokalny

```bash
# Raspberry Pi
ssh bodino@192.168.0.188

# Orange Pi
ssh root@192.168.0.133

# Synology NAS
ssh Bodino@192.168.0.164

# Mac Mini
ssh marekbodynek@192.168.0.106
```

> **Hasła:** Zobacz `credentials.md`

### SSH przez Cloudflare Tunnel

Dodaj do `~/.ssh/config`:

```
Host rpi-ssh.bodino.us.kg
    ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h

Host orange-ssh.bodino.us.kg
    ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h

Host nas-ssh.bodino.us.kg
    ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h

Host macmini-ssh.bodino.us.kg
    ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h
```

### Docker (Home Assistant na RPi)

```bash
# Status
sudo docker ps | grep homeassistant

# Logi
sudo docker logs homeassistant -f

# Restart
sudo docker restart homeassistant
```

### ClawdBot (RPi)

```bash
# Status
systemctl --user status clawdbot-gateway

# Logi
journalctl --user -u clawdbot-gateway -f

# Restart
systemctl --user restart clawdbot-gateway
```

### MS365 MCP (RPi)

```bash
# Status
systemctl --user status ms365-mcp

# Refresh token
~/ms365-refresh-token.sh

# Test API
curl -s -H "Authorization: Bearer $(jq -r .access_token ~/ms365-token.json)" \
  "https://graph.microsoft.com/v1.0/me"
```

---

## Konfiguracje

### Lokalizacje plików konfiguracyjnych

**Raspberry Pi:**
- Homebridge: `/var/lib/homebridge/config.json`
- Zigbee2MQTT: `/opt/zigbee2mqtt/data/configuration.yaml`
- n8n: `/home/bodino/.n8n/config`
- ClawdBot: `~/.clawdbot/clawdbot.json`
- MS365 MCP: `~/.config/systemd/user/ms365-mcp.service`
- Home Assistant: `/home/bodino/homeassistant/`

**Mac Mini:**
- Cloudflare: `~/.cloudflared/config.yml`

**Synology NAS:**
- Cloudflare: `/volume1/cloudflared/config.yml`

**Orange Pi:**
- Cloudflare: `/etc/cloudflared/config.yml`
- Unbound: `/etc/unbound/unbound.conf.d/pi-hole.conf`

> **Szczegóły konfiguracji:** Wyeksportowane do ByteRover

---

## Automatyzacja

### Skrypty (RPi)

| Skrypt | Cron | Funkcja |
|--------|------|---------|
| check-tunnels.sh | */5 * * * * | Sprawdza Cloudflare tunnels |
| update-pihole.sh | 0 */6 * * * | Aktualizacja Pi-hole gravity |
| weekly-update.sh | 0 3 * * 0 | Aktualizacja systemu i serwisów |
| docker-watchdog.sh | */15 * * * * | Monitoring Home Assistant |

Lokalizacja: `/usr/local/bin/`

---

## Backupy

### Harmonogram

| Urządzenie | Kiedy | Lokalizacja na NAS | Retencja |
|------------|-------|-------------------|----------|
| Raspberry Pi | Niedziela 3:00 | `/volume1/backups/rpi/` | 30 dni |
| Orange Pi | Niedziela 3:00 | `/volume1/backups/opi/` | 30 dni |
| Mac Mini | Time Machine | `/volume1/timemachine/` | Auto |

---

## Bezpieczeństwo

- **Fail2ban** - ochrona SSH (RPi + OPi)
- **CrowdSec** - kolaboracyjny IDS/IPS (RPi)
- **Unattended Upgrades** - automatyczne aktualizacje bezpieczeństwa
- **Logwatch** - monitoring logów (codzienne raporty)
- **Pi-hole** - blokowanie malware i phishing (~2M domen)

> **Szczegóły:** Zobacz ByteRover context

---

## Przywracanie

### Raspberry Pi

```bash
# 1. Flash Raspberry Pi OS (Lite 64-bit)
# 2. Ustaw IP: 192.168.0.188
# 3. Zainstaluj serwisy (w kolejności):
#    Pi-hole, Node.js+n8n, Homebridge, Zigbee2MQTT, Docker, Cloudflared, Tailscale

# 4. Przywróć z backupu
mount -t cifs //192.168.0.164/backups /mnt/backups -o user=Bodino
tar -xzf /mnt/backups/rpi/backup-YYYY-MM-DD.tar.gz -C /
```

### Orange Pi

```bash
# 1. Flash Armbian Bookworm
# 2. IP: 192.168.0.133
# 3. Zainstaluj: Pi-hole, Unbound, Cloudflared, Tailscale

# 4. Przywróć z backupu
tar -xzf /mnt/backups/opi/backup-YYYY-MM-DD.tar.gz -C /
```

---

## Historia zmian

- **2026-02-01**: ByteRover (auto-init) + MS365 Recovery + Model Sonnet
- **2026-01-29**: BlueBubbles + MS365 MCP + ClawdBot integracja
- **2025-12-19**: NAS DS224+ + Migracja RPi na NVMe SSD
- **2025-12-14**: Migracja Home Assistant z Mac Mini na RPi
- **2025-12-13**: Migracja smart home z Orange Pi na Raspberry Pi
- **2025-12-11**: Przywracanie RPi + wdrożenie bezpieczeństwa
- **2025-12-05**: Reinstalacja Orange Pi + upgrade do Debian 13

> **Pełna historia:** Zobacz ByteRover context
