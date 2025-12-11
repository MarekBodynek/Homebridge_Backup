# Przywracanie Raspberry Pi (nowa karta SD)

## Status: ✅ ZAKOŃCZONE

**Data:** 2025-12-11
**Powód:** Uszkodzona karta SD (błędy EXT4)
**Backup n8n:** `/Users/marekbodynek/n8n-backup-20251201/` na Mac Mini (968 MB)

---

## Plan przywracania

### Faza 1: Podstawowa konfiguracja
- [x] 1. Zainstalować Raspberry Pi OS (Lite 64-bit)
- [x] 2. Skonfigurować użytkownika `bodino` (hasło: `Keram1qazXSW@`)
- [x] 3. Ustawić statyczne IP: `192.168.0.189`
- [x] 4. Włączyć SSH

### Faza 2: Pi-hole + Unbound (DNS)
- [x] 5. Zainstalować Pi-hole (`curl -sSL https://install.pi-hole.net | bash`)
- [x] 6. Ustawić hasło Pi-hole: `bodino44`
- [x] 7. Zainstalować Unbound
- [x] 8. Skonfigurować Unbound na port 5335
- [x] 9. Ustawić Pi-hole upstream DNS na `127.0.0.1#5335`
- [x] 10. Dodać listy blokujące (Firebog + polskie)

### Faza 3: Cloudflare Tunnel
- [x] 11. Zainstalować cloudflared
- [x] 12. Zalogować do Cloudflare (`cloudflared tunnel login`)
- [x] 13. Skonfigurować tunel (ID: `278a7b8a-8f20-4854-95f9-75ef20c332a2`)
- [x] 14. Ustawić serwisy:
    - `rpi-ssh.bodino.us.kg` → SSH
    - `n8n.bodino.us.kg` → localhost:5678
- [x] 15. Włączyć autostart cloudflared

### Faza 4: Tailscale
- [x] 16. Zainstalować Tailscale
- [x] 17. Zalogować do sieci
- [x] 18. Zweryfikować IP Tailscale (nowy IP: 100.112.174.109)

### Faza 5: n8n
- [x] 19. Zainstalować Node.js 22
- [x] 20. Zainstalować n8n (`npm install -g n8n`)
- [x] 21. Skopiować backup z Mac Mini do `/home/bodino/.n8n/`
- [x] 22. Utworzyć systemd service dla n8n
- [x] 23. Włączyć autostart n8n
- [x] 24. Zweryfikować działanie n8n

### Faza 6: Skrypty automatyzacji
- [x] 25. Utworzyć klucze SSH (`ssh-keygen`)
- [x] 26. Skopiować klucz do Orange Pi i Mac Mini
- [x] 27. Wdrożyć `check-tunnels.sh` + cron (*/5 * * * *)
- [x] 28. Wdrożyć `update-pihole.sh` + cron (0 */6 * * *)
- [x] 29. Wdrożyć `weekly-update.sh` + cron (0 3 * * 0)
- [x] 30. Wdrożyć logrotate config

### Faza 7: Weryfikacja końcowa
- [x] 31. Sprawdzić wszystkie serwisy (cloudflared, n8n, pihole-FTL, tailscaled, unbound)
- [x] 32. Przetestować dostęp przez Cloudflare tunnel
- [x] 33. Przetestować n8n.bodino.us.kg
- [x] 34. Uruchomić skrypty testowo

---

## Review - Przywracanie zakończone (2025-12-11)

### Podsumowanie
Pełne przywracanie Raspberry Pi po awarii karty SD zakończone pomyślnie. System przywrócony od zera w ~1 godzinę.

### Problemy napotkane i rozwiązania
1. **GitHub 504 timeout** przy pobieraniu Pi-hole FTL - rozwiązano kopiując binarny plik z Orange Pi
2. **Cloudflare tunnel** - początkowo próba z tokenem, przełączono na lokalny plik config z ingress rules
3. **DNS na świeżym systemie** - tymczasowo ustawiono 8.8.8.8 w /etc/resolv.conf

### Zmiany względem poprzedniej instalacji
- Nowy IP Tailscale: `100.112.174.109` (poprzednio: 100.107.249.87)
- Cloudflare tunnel używa lokalnego config zamiast tokena z dashboard

### Konfiguracja Tailscale (stan końcowy)
- **Mac Mini**: ON - połączony z Apple TV (Jellyfin streaming)
- **Orange Pi**: ON
- **Raspberry Pi**: ON
- **Apple TV**: Dostępny przez Tailscale (100.85.3.71)

---

## Dane dostępowe

| Parametr | Wartość |
|----------|---------|
| **IP lokalne** | 192.168.0.189 |
| **IP Tailscale** | 100.107.249.87 |
| **User** | bodino |
| **Hasło user** | Keram1qazXSW@ |
| **Hasło Pi-hole** | bodino44 |
| **Tunel ID** | 278a7b8a-8f20-4854-95f9-75ef20c332a2 |

## Cloudflare Tunnel URLs

| Serwis | URL |
|--------|-----|
| SSH | rpi-ssh.bodino.us.kg |
| n8n | n8n.bodino.us.kg |

---

# Skrypty automatyzacji dla Raspberry Pi i Orange Pi

## Sieć lokalna (Koszalin)

| Urządzenie | Lokalne IP | User |
|------------|------------|------|
| **Raspberry Pi** | 192.168.0.189 | bodino |
| **Orange Pi** | 192.168.0.133 | root |
| **Mac Mini** | 192.168.0.106 | marekbodynek |

## Serwisy na urządzeniach

| Urządzenie | Serwisy |
|------------|---------|
| **Raspberry Pi** | cloudflared, n8n, pihole-FTL, tailscaled, unbound |
| **Orange Pi** | cloudflared, homebridge, mosquitto, pihole-FTL, tailscaled, unbound, zigbee2mqtt |
| **Mac Mini** | cloudflared, tailscaled |

---

## Wymagania wstępne

### Konfiguracja SSH z Raspberry Pi
Przed wdrożeniem skryptu check-tunnels.sh trzeba skonfigurować klucze SSH:

```bash
# Na Raspberry Pi (jako root):
ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519

# Skopiuj klucz do Orange Pi:
ssh-copy-id -i /root/.ssh/id_ed25519.pub root@192.168.0.133

# Skopiuj klucz do Mac Mini:
ssh-copy-id -i /root/.ssh/id_ed25519.pub marekbodynek@192.168.0.106

# Test połączeń:
ssh -o BatchMode=yes root@192.168.0.133 "echo OK"
ssh -o BatchMode=yes marekbodynek@192.168.0.106 "echo OK"
```

---

## Plan

### Skrypt 1: Sprawdzanie WSZYSTKICH tuneli (co 5 minut)
**Lokalizacja:** Raspberry Pi (`/usr/local/bin/check-tunnels.sh`)
**Cron:** `*/5 * * * *`

**Działanie:**
- Sprawdza status cloudflared na: Raspberry Pi, Orange Pi, Mac Mini
- Jeśli nie działa → restartuje
- Loguje do `/var/log/tunnel-check.log`

```bash
#!/bin/bash
LOG="/var/log/tunnel-check.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Funkcja dla Linux (systemctl)
check_linux_tunnel() {
    local HOST=$1
    local NAME=$2
    local USER=$3

    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes ${USER}@${HOST} "systemctl is-active --quiet cloudflared" 2>/dev/null; then
        echo "$DATE - $NAME cloudflared down, restarting..." >> $LOG
        ssh -o ConnectTimeout=5 -o BatchMode=yes ${USER}@${HOST} "systemctl restart cloudflared" 2>/dev/null
        sleep 5
        if ssh -o ConnectTimeout=5 -o BatchMode=yes ${USER}@${HOST} "systemctl is-active --quiet cloudflared" 2>/dev/null; then
            echo "$DATE - $NAME cloudflared restarted OK" >> $LOG
        else
            echo "$DATE - $NAME cloudflared FAILED to restart" >> $LOG
        fi
    fi
}

# Funkcja dla macOS (launchctl) - com.cloudflare.macmini-tunnel
check_macos_tunnel() {
    local HOST=$1
    local NAME=$2
    local USER=$3
    local SERVICE="com.cloudflare.macmini-tunnel"

    # Sprawdź czy serwis działa (ma PID)
    if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes ${USER}@${HOST} "launchctl list ${SERVICE} 2>/dev/null | grep -q PID" 2>/dev/null; then
        echo "$DATE - $NAME cloudflared down, restarting..." >> $LOG
        ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes ${USER}@${HOST} "launchctl stop ${SERVICE}; launchctl start ${SERVICE}" 2>/dev/null
        sleep 5
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes ${USER}@${HOST} "launchctl list ${SERVICE} 2>/dev/null | grep -q PID" 2>/dev/null; then
            echo "$DATE - $NAME cloudflared restarted OK" >> $LOG
        else
            echo "$DATE - $NAME cloudflared FAILED to restart" >> $LOG
        fi
    fi
}

# Lokalny tunel (Raspberry Pi)
if ! systemctl is-active --quiet cloudflared; then
    echo "$DATE - Raspberry Pi cloudflared down, restarting..." >> $LOG
    systemctl restart cloudflared
    sleep 5
    if systemctl is-active --quiet cloudflared; then
        echo "$DATE - Raspberry Pi cloudflared restarted OK" >> $LOG
    else
        echo "$DATE - Raspberry Pi cloudflared FAILED to restart" >> $LOG
    fi
fi

# Orange Pi (Linux - systemctl)
check_linux_tunnel "192.168.0.133" "Orange Pi" "root"

# Mac Mini (macOS - launchctl)
check_macos_tunnel "192.168.0.106" "Mac Mini" "marekbodynek"
```

---

### Skrypt 2: Aktualizacja list Pi-hole (co 6 godzin)
**Lokalizacja:** Oba urządzenia (`/usr/local/bin/update-pihole.sh`)
**Cron:** `0 */6 * * *`

**Działanie:**
- Uruchamia `pihole -g` (gravity update)
- Loguje wynik

```bash
#!/bin/bash
LOG="/var/log/pihole-update.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "$DATE - Starting Pi-hole gravity update" >> $LOG
pihole -g >> $LOG 2>&1
echo "$DATE - Update completed" >> $LOG
```

---

### Skrypt 3a: Tygodniowy update - Orange Pi (niedziela 3:00)
**Lokalizacja:** Orange Pi (`/usr/local/bin/weekly-update.sh`)
**Cron:** `0 3 * * 0`

**Serwisy:** cloudflared, homebridge, mosquitto, pihole-FTL, tailscaled, unbound, zigbee2mqtt

**Działanie:**
1. Backup konfiguracji do /root/backups/
2. Usunięcie backupów starszych niż 30 dni
3. Pełna aktualizacja systemu (apt update, upgrade, dist-upgrade, autoremove, autoclean)
4. Aktualizacja Homebridge (npm)
5. Aktualizacja Zigbee2MQTT (git + npm)
6. Aktualizacja Pi-hole
7. Restart serwisów

```bash
#!/bin/bash
LOG="/var/log/weekly-update.log"
BACKUP_DIR="/root/backups"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
BACKUP_DATE=$(date '+%Y-%m-%d')

echo "========== $DATE ==========" >> $LOG
echo "Starting weekly update on Orange Pi..." >> $LOG

# 1. Backup
echo "$DATE - Creating backup..." >> $LOG
mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/backup-$BACKUP_DATE.tar.gz \
    /etc/cloudflared \
    /var/lib/homebridge \
    /opt/zigbee2mqtt/data \
    /etc/pihole \
    /etc/dnsmasq.d \
    /etc/unbound \
    /etc/mosquitto \
    2>> $LOG
echo "$DATE - Backup created: backup-$BACKUP_DATE.tar.gz" >> $LOG

# 2. Usunięcie starych backupów (>30 dni)
find $BACKUP_DIR -name "backup-*.tar.gz" -mtime +30 -delete
echo "$DATE - Old backups cleaned" >> $LOG

# 3. System packages (apt) - tailscale, cloudflared, unbound, mosquitto
echo "$DATE - Updating system packages..." >> $LOG
apt update >> $LOG 2>&1
apt upgrade -y >> $LOG 2>&1
apt dist-upgrade -y >> $LOG 2>&1
apt autoremove -y >> $LOG 2>&1
apt autoclean >> $LOG 2>&1

# 4. Homebridge
echo "$DATE - Updating Homebridge..." >> $LOG
npm update -g homebridge homebridge-config-ui-x >> $LOG 2>&1

# 5. Zigbee2MQTT
echo "$DATE - Updating Zigbee2MQTT..." >> $LOG
cd /opt/zigbee2mqtt
git pull >> $LOG 2>&1
npm ci >> $LOG 2>&1

# 6. Pi-hole
echo "$DATE - Updating Pi-hole..." >> $LOG
pihole -up >> $LOG 2>&1

# 7. Restart serwisów
echo "$DATE - Restarting services..." >> $LOG
systemctl restart cloudflared >> $LOG 2>&1
systemctl restart pihole-FTL >> $LOG 2>&1
systemctl restart homebridge >> $LOG 2>&1
systemctl restart zigbee2mqtt >> $LOG 2>&1
systemctl restart mosquitto >> $LOG 2>&1
systemctl restart unbound >> $LOG 2>&1

echo "$DATE - Weekly update completed on Orange Pi" >> $LOG
```

---

### Skrypt 3b: Tygodniowy update - Raspberry Pi (niedziela 3:00)
**Lokalizacja:** Raspberry Pi (`/usr/local/bin/weekly-update.sh`)
**Cron:** `0 3 * * 0`

**Serwisy:** cloudflared, n8n, pihole-FTL, tailscaled, unbound

**Działanie:**
1. Backup konfiguracji do /home/bodino/backups/
2. Usunięcie backupów starszych niż 30 dni
3. Pełna aktualizacja systemu (apt update, upgrade, dist-upgrade, autoremove, autoclean)
4. Aktualizacja n8n (npm)
5. Aktualizacja Pi-hole
6. Restart serwisów

```bash
#!/bin/bash
LOG="/var/log/weekly-update.log"
BACKUP_DIR="/home/bodino/backups"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
BACKUP_DATE=$(date '+%Y-%m-%d')

echo "========== $DATE ==========" >> $LOG
echo "Starting weekly update on Raspberry Pi..." >> $LOG

# 1. Backup
echo "$DATE - Creating backup..." >> $LOG
mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/backup-$BACKUP_DATE.tar.gz \
    /etc/cloudflared \
    /home/bodino/.n8n \
    /etc/pihole \
    /etc/dnsmasq.d \
    /etc/unbound \
    2>> $LOG
echo "$DATE - Backup created: backup-$BACKUP_DATE.tar.gz" >> $LOG

# 2. Usunięcie starych backupów (>30 dni)
find $BACKUP_DIR -name "backup-*.tar.gz" -mtime +30 -delete
echo "$DATE - Old backups cleaned" >> $LOG

# 3. System packages (apt) - tailscale, cloudflared, unbound
echo "$DATE - Updating system packages..." >> $LOG
apt update >> $LOG 2>&1
apt upgrade -y >> $LOG 2>&1
apt dist-upgrade -y >> $LOG 2>&1
apt autoremove -y >> $LOG 2>&1
apt autoclean >> $LOG 2>&1

# 4. n8n
echo "$DATE - Updating n8n..." >> $LOG
npm update -g n8n >> $LOG 2>&1

# 5. Pi-hole
echo "$DATE - Updating Pi-hole..." >> $LOG
pihole -up >> $LOG 2>&1

# 6. Restart serwisów
echo "$DATE - Restarting services..." >> $LOG
systemctl restart cloudflared >> $LOG 2>&1
systemctl restart pihole-FTL >> $LOG 2>&1
systemctl restart n8n >> $LOG 2>&1
systemctl restart unbound >> $LOG 2>&1

echo "$DATE - Weekly update completed on Raspberry Pi" >> $LOG
```

---

### Logrotate - rotacja logów (1 miesiąc)
**Lokalizacja:** Oba urządzenia (`/etc/logrotate.d/automation-scripts`)

```
/var/log/tunnel-check.log
/var/log/pihole-update.log
/var/log/weekly-update.log {
    monthly
    rotate 1
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
```

---

## Zadania do wykonania

### Przygotowanie
- [x] 1. Usunąć stary cloudflared-watchdog.sh i cron na Orange Pi
- [x] 2. Skonfigurować klucze SSH z Raspberry Pi do Orange Pi i Mac Mini

### Wdrożenie skryptów
- [x] 3. Utworzyć check-tunnels.sh na Raspberry Pi + cron
- [x] 4. Utworzyć update-pihole.sh na Raspberry Pi i Orange Pi + cron
- [x] 5. Utworzyć weekly-update.sh na Raspberry Pi i Orange Pi + cron
- [x] 6. Utworzyć logrotate config na Raspberry Pi i Orange Pi

### Weryfikacja
- [x] 7. Przetestować wszystkie skrypty
- [x] 8. Zweryfikować logi

## Archiwum poprzednich zadań

### ✅ AUTOMATYZACJA SKRYPTÓW ZAKOŃCZONA (2025-12-10)

**Podsumowanie wdrożenia:**

| Skrypt | Lokalizacja | Cron | Status |
|--------|-------------|------|--------|
| check-tunnels.sh | Raspberry Pi | */5 * * * * | ✅ Działa |
| update-pihole.sh | Raspberry Pi + Orange Pi | 0 */6 * * * | ✅ Działa |
| weekly-update.sh | Raspberry Pi + Orange Pi | 0 3 * * 0 | ✅ Składnia OK |
| logrotate | Raspberry Pi + Orange Pi | monthly | ✅ Skonfigurowany |

**Uwagi:**
- Mac Mini używa custom launchd service `com.cloudflare.macmini-tunnel` (nie homebrew)
- Skrypt check-tunnels.sh sprawdza wszystkie 3 urządzenia przez SSH z Raspberry Pi
- Backupy tworzone w `/home/bodino/backups/` (RPi) i `/root/backups/` (OPi)
- Stare backupy (>30 dni) automatycznie usuwane
- Logi rotowane co miesiąc z kompresją

---

### ✅ UPGRADE DEBIAN 13 ZAKOŃCZONY (2025-12-02)

System Orange Pi zaktualizowany do Debian 13 (trixie). Wszystkie serwisy działają.
