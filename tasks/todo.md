# Lista zadań

> **Uwaga:** Szczegółowa dokumentacja infrastruktury znajduje się w [README.md](../README.md)

---

## Aktywne zadania

### MacBook Pro - naprawa wydajności (2025-01-24)

**Diagnoza:**
- **Load Average: 17-33** (powinno być <10 dla 10-rdzeniowego M1 Pro)
- **850 procesów** uruchomionych
- **30GB/32GB RAM** zajęte

**Problematyczne procesy:**
| Proces | CPU | Problem |
|--------|-----|---------|
| WindowServer | 37% | Zbyt wiele okien/animacji |
| contactsd | 26% | Synchronizacja kontaktów iCloud |
| AirPlayXPCHelper | 25% | Aktywne AirPlay? |
| AddressBookManager | 19.5% | Indeksowanie kontaktów |
| identityservicesd | 18% | Serwisy iCloud/Apple ID |
| logioptionsplus_updater | 13.6% | Logitech sprawdza aktualizacje |

**Plan naprawy:**

- [ ] 1. Zabić procesy kontaktów (natychmiastowa ulga)
- [ ] 2. Zrestartować Logitech Options
- [ ] 3. Wyłączyć niepotrzebne aplikacje w tle
- [ ] 4. Sprawdzić/wyłączyć AirPlay
- [ ] 5. Wyczyścić cache systemu
- [ ] 6. Sprawdzić stan po naprawie

---

### RetroArch - do zrobienia lokalnie (wymaga fizycznego dostępu)

- [ ] Ustawić wyjście audio na HDMI (`raspi-config` → Audio → HDMI)
- [ ] Przetestować dźwięk (`speaker-test -c 2`)
- [ ] Skopiować ROMy do folderu "Retro Gaming ROMS" na Mac Mini
- [ ] Przetestować gry

**Uwagi:**
- EmulationStation pominięte - brak oficjalnej wersji dla Linux aarch64
- PPSSPP niekompatybilne - RPi 5 używa 16KB page size

---

## Historia ukończonych zadań

### 2025-12-14: Migracja Home Assistant z Mac Mini na Raspberry Pi 5

**Co zostało zrobione:**
1. Zainstalowano Docker na RPi 5 (`apt-get install docker.io docker-compose`)
2. Utworzono backup HA z Mac Mini (~926MB)
3. Przeniesiono konfigurację do `/home/bodino/homeassistant/`
4. Uruchomiono kontener HA:
   ```bash
   sudo docker run -d \
     --name homeassistant \
     --restart=unless-stopped \
     --privileged \
     -v /home/bodino/homeassistant:/config \
     -v /etc/localtime:/etc/localtime:ro \
     -v /run/dbus:/run/dbus:ro \
     --network=host \
     ghcr.io/home-assistant/home-assistant:stable
   ```
5. Zaktualizowano Cloudflare Tunnel - dodano `ha.bodino.us.kg` do `/etc/cloudflared/config.yml` na RPi
6. Przekierowano DNS route: `cloudflared tunnel route dns --overwrite-dns 278a7b8a-8f20-4854-95f9-75ef20c332a2 ha.bodino.us.kg`
7. Naprawiono problem z utratą użytkownika - przywrócono katalog `.storage` z backupu

**Dostęp do Home Assistant:**
- URL: https://ha.bodino.us.kg
- Username: `bodino`
- Lokalizacja konfiguracji: `/home/bodino/homeassistant/`
- Kontener Docker: `homeassistant`

**Komendy zarządzania HA na RPi:**
```bash
# Status
sudo docker ps | grep homeassistant

# Logi
sudo docker logs homeassistant -f

# Restart
sudo docker restart homeassistant

# Stop/Start
sudo docker stop homeassistant
sudo docker start homeassistant
```

**Dostęp SSH do RPi 5:**
```bash
# Przez Cloudflare Tunnel (z dowolnego miejsca)
ssh -o ProxyCommand="cloudflared access ssh --hostname rpi-ssh.bodino.us.kg" bodino@rpi-ssh.bodino.us.kg

# Lokalnie (w sieci domowej)
ssh bodino@192.168.0.188
# Hasło: Keram1qazXSW@
```

---

### 2025-12-13: Migracja smart home z Orange Pi na Raspberry Pi
- Przeniesiono: Homebridge, Zigbee2MQTT, Mosquitto
- Zaktualizowano Cloudflare Tunnel routes
- Zaktualizowano skrypty weekly-update.sh
- Orange Pi teraz tylko: Pi-hole (backup DNS)

### 2025-12-12: RetroArch na Raspberry Pi
- Zainstalowano RetroArch + emulatory
- Skonfigurowano SMB mount dla ROMów z Mac Mini

### 2025-12-11: Przywracanie Raspberry Pi
- Pełne przywracanie po awarii karty SD
- Wdrożenie Fail2ban, CrowdSec, unattended-upgrades, Logwatch
- Konfiguracja backupów (codzienne + tygodniowe)

### 2025-12-10: Automatyzacja skryptów
- check-tunnels.sh (co 5 min)
- update-pihole.sh (co 6h)
- weekly-update.sh (niedziela 3:00)
- logrotate

### 2025-12-05: Reinstalacja Orange Pi
- Przywracanie po awarii karty SD
- Upgrade do Debian 13 (Trixie)
