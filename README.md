# Homebridge & Zigbee2MQTT Backup

Backup konfiguracji systemu smart home na Orange Pi.

## System

- **OS:** Armbian 25.5.1 (Debian 12 Bookworm)
- **Kernel:** 6.12.23-current-sunxi64
- **Hardware:** Orange Pi Zero2
- **IP:** 192.168.0.133

### Dane logowania
- **root:** `Orange1234!`
- **użytkownik:** `orange` / hasło: `orange`

**Status:** Wszystkie serwisy działają poprawnie po reinstalacji 2025-12-05.

## Komponenty

### Homebridge
- **Wersja:** 1.11.1
- **Config UI X:** 5.9.0
- **Plugins:**
  - homebridge-ewelink@12.3.3
  - homebridge-z2m@1.9.3

### Zigbee2MQTT
- **Wersja:** 2.7.0
- **MQTT:** Mosquitto localhost:1883

### MQTT
- **Broker:** Mosquitto
- **User:** mqtt
- **Topic:** zigbee2mqtt

### Pi-hole
- **Wersja:** v6.3 (Core), v6.4 (Web), v6.4.1 (FTL)
- **Panel:** http://192.168.0.133/admin
- **Hasło:** bodino44
- **Blokowane domeny:** 789,404 (Firebog + polskie listy)
- **Upstream DNS:** Unbound (127.0.0.1#5335)
- **Automatyczna aktualizacja list:** co 6 godzin

### Unbound
- **Port:** 5335
- **Funkcja:** Rekursywny resolver DNS (brak zewnętrznych providerów)
- **Root hints:** Aktualizowane 1. dnia każdego miesiąca
- **Bezpieczeństwo:** DNSSEC, qname-minimisation

## Backupy

### Pełne archiwa
- `homebridge-backup-20251202-141551.tar.gz` - Pełny backup /var/lib/homebridge
- `zigbee2mqtt-backup-20251202-141551.tar.gz` - Pełny backup /opt/zigbee2mqtt/data
- `tailscale-backup-20251202-141551.tar.gz` - Pełny backup /var/lib/tailscale

**Uwaga:** Backup Pi-hole (~90 MB) tylko na Orange Pi (`~/backups/`) - za duży dla GitHub.

### Pliki konfiguracyjne
- `homebridge-config.json` - Konfiguracja Homebridge
- `zigbee2mqtt-config.yaml` - Konfiguracja Zigbee2MQTT

## Historia zmian

### 2025-12-05
- Pełna reinstalacja systemu po awarii karty SD
- Przywrócono wszystkie serwisy: Mosquitto, Zigbee2MQTT, Homebridge, Pi-hole, Tailscale, Cloudflare Tunnel
- Utworzono pełny backup systemu tar.gz (887MB)
- Backup skopiowany na Mac Mini: `~/Backups/orangepi-backup-2025-12-05.tar.gz`
- Skonfigurowano watchdog Cloudflare Tunnel (cron co 5 minut):
  - Orange Pi: sprawdza cloudflared + Homebridge + Pi-hole + Zigbee2MQTT
  - Mac Mini: sprawdza cloudflared
- Skrypt watchdog: `/usr/local/bin/cloudflared-watchdog.sh`
- Logi watchdog: `/var/log/cloudflared-watchdog.log`
- Tailscale z subnet routing 192.168.0.0/24

### 2025-12-02
- Upgrade Debian 12 (Bookworm) → 13 (Trixie)
- Upgrade Pi-hole v6.2.2 → v6.3 (Core), v6.4 (Web), v6.4.1 (FTL)
- Naprawiono uprawnienia /etc/pihole/versions
- Naprawiono zmienną środowiskową TERM dla Pi-hole
- Naprawiono konfigurację dpkg (base-files)
- Aktualizacja backupów (Homebridge, Zigbee2MQTT, Tailscale)

### 2025-11-27
- Zamiana WireGuard na Tailscale (łatwiejsza konfiguracja, wsparcie Apple TV)
- Orange Pi jako subnet router (192.168.0.0/24)
- Dostęp do całej sieci domowej przez Tailscale
- Streaming filmów z MacMini na Apple TV przez Infuse

### 2025-11-26
- Instalacja WireGuard VPN (wireguard-go dla kernel 4.9) - zastąpione przez Tailscale
- Konfiguracja Cloudflare DDNS (vpn.bodino.us.kg)
- Automatyczna aktualizacja IP co 5 minut
- Port forwarding 51820 UDP na routerze TP-Link
- Klient VPN skonfigurowany na MacBooku

### 2025-11-25
- Naprawa przycisku Zigbee "Włącznik brama garażowa" (rekonfiguracja urządzenia)
- Naprawa wyświetlania przycisku w HomeKit (usunięcie uszkodzonego cache)
- Przycisk działa z akcjami: single, double, long

### 2025-11-22
- Instalacja Unbound (rekursywny resolver DNS)
- Pi-hole używa teraz Unbound zamiast Cloudflare/Google
- Dodanie 27 list blokujących z Firebog
- Dodanie 7 polskich list blokujących (KADhosts, CERT Polska, Polish Ads Filter)
- Ręczne blokowanie polskich domen reklamowych (onetads.pl, gemius.pl, adocean)
- Automatyczna aktualizacja list Pi-hole co 6 godzin
- Backup URL-i adlist w cotygodniowej konserwacji
- Odświeżenie gravity po aktualizacji systemu
- Konfiguracja DNS na routerze (192.168.0.133)
- Instalacja Fail2ban (ochrona przed brute-force SSH)
- SSH hardening (brak root, max 3 próby)
- Automatyczne aktualizacje bezpieczeństwa (unattended-upgrades)

### 2025-11-21
- Aktualizacja systemu (apt upgrade, npm 11.6.3, pnpm 10.23.0)
- Aktualizacja backupów (Homebridge, Zigbee2MQTT, Pi-hole)
- Konfiguracja Cloudflare Tunnel (SSH + WWW)

### 2025-11-16
- Wyłączenie harmonogramów Zigbee w regulatorach TRV (konflikt z HomeKit)
- Ustawienie 3/4 regulatorów na tryb MANUAL (HomeKit kontroluje temperaturę)
- Utworzenie skryptu disable-zigbee-schedules.sh
- Aktualizacja backupów (Homebridge, Zigbee2MQTT, Pi-hole)

### 2025-11-14
- Upgrade Debian 11 → 12 (Bookworm)
- Upgrade Node.js 20 → 22
- Upgrade npm 10.9.4 → 11.6.2
- Rebuild Homebridge dla Node.js v22
- Naprawa Mosquitto MQTT (wykomentowano pid_file)
- Instalacja Pi-hole v6.2.2 (blokowanie reklam sieciowych)
- Utworzenie pełnych backupów (Homebridge, Zigbee2MQTT, Pi-hole)

## Urządzenia Zigbee

### Czujniki temperatury
- Czujnik temperatury jadalnia
- Czujnik temperatury łazienka góra
- Czujnik temperatury hall
- Czujnik temperatury garaż

### Regulatory kaloryferów (TRV)
- Regulator kaloryfer jadalnia
- Regulator kaloryfer sypialnia
- Regulator kaloryfer biuro
- Regulator kaloryfer pokój Patryka

**WAŻNE:** Wszystkie regulatory są skonfigurowane w trybie MANUAL, aby HomeKit był głównym źródłem kontroli temperatury. Harmonogramy Zigbee są wyłączone, aby nie kolidowały z automatyzacjami HomeKit.

### Inne urządzenia
- Czujnik ruchu łazienka dół
- Włącznik brama garażowa

## Przywracanie z backupu

### Homebridge
```bash
sudo systemctl stop homebridge
sudo rm -rf /var/lib/homebridge
sudo tar -xzf homebridge-backup-20251121-205023.tar.gz -C /var/lib/
sudo systemctl start homebridge
```

### Zigbee2MQTT
```bash
sudo systemctl stop zigbee2mqtt
sudo rm -rf /opt/zigbee2mqtt/data
sudo tar -xzf zigbee2mqtt-backup-20251121-205023.tar.gz -C /opt/zigbee2mqtt/
sudo systemctl start zigbee2mqtt
```

### Pi-hole
```bash
sudo systemctl stop pihole-FTL
sudo rm -rf /etc/pihole
sudo tar -xzf pihole-backup-20251127-011658.tar.gz -C /etc/
sudo systemctl start pihole-FTL
```

### Tailscale
```bash
sudo systemctl stop tailscaled
sudo rm -rf /var/lib/tailscale
sudo tar -xzf tailscale-backup-20251127-012915.tar.gz -C /var/lib/
sudo systemctl start tailscaled
```

## Zarządzanie harmonogramami regulatorów

### Problem: Konflikt między Zigbee a HomeKit

Regulatory TRV (Thermostatic Radiator Valve) mają wbudowane harmonogramy, które mogą kolidować z automatyzacjami HomeKit. Aby HomeKit był głównym źródłem kontroli:

1. **Wszystkie regulatory są w trybie MANUAL** - nie używają wbudowanych harmonogramów Zigbee
2. **HomeKit kontroluje temperaturę** - przez automatyzacje i sceny
3. **Brak konfliktów** - harmonogramy Zigbee są wyłączone

### Wyłączenie harmonogramów Zigbee

Jeśli regulatory wróciły do trybu AUTO lub mają aktywne harmonogramy, uruchom skrypt:

```bash
chmod +x disable-zigbee-schedules.sh
./disable-zigbee-schedules.sh
```

Skrypt ustawi wszystkie regulatory na:
- `preset: manual` - wyłącza harmonogramy Zigbee
- `system_mode: heat` - zapewnia tryb grzania bez automatyki

### Weryfikacja

Sprawdź ustawienia w:
- **Zigbee2MQTT Frontend:** http://localhost:8080 (lub http://192.168.0.133:8080)
- **Aplikacja Home:** iOS/macOS

Każdy regulator powinien pokazywać:
- Preset: Manual
- System Mode: Heat

## Automatyczna konserwacja

### Cotygodniowa konserwacja
Skrypt `~/weekly-maintenance.sh` uruchamia się automatycznie **co niedzielę o 3:00**:

1. **Backup** → `/home/orangepi/backups/`
   - Homebridge, Zigbee2MQTT, Pi-hole, Tailscale
   - URL-e list Pi-hole (pihole-adlists-*.txt)
   - Stare backupy (>30 dni) usuwane automatycznie

2. **Aktualizacja**
   - apt upgrade
   - npm, pnpm
   - Tailscale

3. **Odświeżenie Pi-hole**
   - `pihole -g` po aktualizacji systemu

4. **Sprawdzenie aktualizacji Zigbee**
   - Firmware urządzeń OTA

5. **Sprawdzenie aktualizacji Homebridge**
   - Pluginy npm

**Logi:** `/var/log/weekly-maintenance.log`

### Codzienna konserwacja pamięci
Skrypt `~/memory-cleanup.sh` uruchamia się automatycznie **codziennie o 4:00**:
- Czyści cache systemowy (`drop_caches`)
- Restartuje Pi-hole jeśli używa >150 MB RAM
- Orange Pi ma tylko 964 MB RAM

**Logi:** `/var/log/memory-cleanup.log`

### Aktualizacja list Pi-hole
Gravity update uruchamia się automatycznie **co 6 godzin** (0:00, 6:00, 12:00, 18:00):
- Pobiera najnowsze wersje list blokujących (Firebog)
- Przebudowuje bazę gravity.db

**Logi:** `/var/log/pihole-gravity-update.log`

## Dostęp zdalny

### Tailscale VPN (zalecane)
- **Orange Pi IP:** 100.73.24.70
- **Subnet routing:** 192.168.0.0/24 (cała sieć domowa)
- **DNS przez VPN:** Pi-hole (192.168.0.133)

**Instalacja:**
- macOS: App Store lub `brew install --cask tailscale`
- Apple TV: App Store → Tailscale
- Zaloguj się na to samo konto Tailscale

**Przez Tailscale masz dostęp do:**
- Cała sieć domowa (192.168.0.x) przez subnet routing
- MacMini (192.168.0.106) - dysk z filmami
- Pi-hole, Homebridge, Zigbee2MQTT
- Udostępnione dyski, drukarki, inne urządzenia

**Panel administracyjny:** https://login.tailscale.com/admin

### Streaming na Apple TV (Infuse)
1. Zainstaluj **Tailscale** na Apple TV (App Store)
2. Zaloguj się na to samo konto
3. W **Infuse** dodaj źródło SMB:
   - Adres: `192.168.0.106`
   - Ścieżka: `Seagate25_5T/!!!!Filmy NB`
   - Użytkownik/hasło: dane do MacMini

### Cloudflare Tunnel (alternatywa)

| Serwis | URL |
|--------|-----|
| **Zigbee2MQTT** | https://zigbee.bodino.us.kg |
| **Homebridge** | https://homebridge.bodino.us.kg |
| **Pi-hole** | https://pihole.bodino.us.kg |
| **SSH Orange Pi** | `ssh -o ProxyCommand="cloudflared access ssh --hostname %h" orangepi@orangepi-ssh.bodino.us.kg` |
| **SSH Mac Mini** | `ssh -o ProxyCommand="cloudflared access ssh --hostname %h" marekbodynek@macmini-ssh.bodino.us.kg` |

### SSH do Mac Mini (bezpośredni tunel)

```bash
ssh -o ProxyCommand="cloudflared access ssh --hostname %h" marekbodynek@macmini-ssh.bodino.us.kg
```

- **IP lokalne:** 192.168.0.106
- **Użytkownik:** marekbodynek
- **Hasło:** Keram1qazXSW@3edcV
- **Tunel ID:** 877197db-185e-43e9-983b-0fd95bd422ba

**Healthcheck Orange Pi:** Skrypt `~/tunnel-healthcheck.sh` sprawdza tunele **co 5 minut** i automatycznie restartuje cloudflared jeśli nie działa.

**Logi:** `/var/log/tunnel-healthcheck.log`

## Bezpieczeństwo

### Fail2ban
- Blokuje IP po **3 nieudanych logowaniach SSH** na **24 godziny**
- Status: `sudo fail2ban-client status sshd`
- Odblokowanie IP: `sudo fail2ban-client set sshd unbanip <IP>`

### SSH Hardening
- Root login wyłączony
- Max 3 próby logowania
- Timeout 30 sekund

### Automatyczne aktualizacje bezpieczeństwa
- Codzienne sprawdzanie aktualizacji
- Automatyczna instalacja poprawek bezpieczeństwa
- Bez automatycznego restartu

### Cloudflare Tunnel
- Brak otwartych portów z internetu
- Cały ruch przez szyfrowany tunel
- Healthcheck co 5 minut

## Notatki

- System zaktualizowany 2025-11-25
- Wszystkie serwisy działają poprawnie
- Frontend Zigbee2MQTT bez zabezpieczenia hasłem (próba dodania auth zakończyła się błędem YAML)
- **HomeKit jest głównym źródłem kontroli temperatury** - harmonogramy Zigbee wyłączone
- **Pi-hole blokuje 789,404 domen** - Firebog + polskie listy, aktualizowane co 6h
