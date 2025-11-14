# Homebridge & Zigbee2MQTT Backup

Backup konfiguracji systemu smart home na Orange Pi.

## System

- **Debian:** 12 (Bookworm)
- **Node.js:** v22.21.0
- **npm:** 11.6.2

## Komponenty

### Homebridge
- **Wersja:** 1.11.1
- **Config UI X:** 5.9.0
- **Plugins:**
  - homebridge-ewelink@12.3.3
  - homebridge-z2m@1.9.3

### Zigbee2MQTT
- **Wersja:** 2.6.3
- **MQTT:** Mosquitto localhost:1883

### MQTT
- **Broker:** Mosquitto
- **User:** mqtt
- **Topic:** zigbee2mqtt

## Backupy

### Pełne archiwa
- `homebridge-backup-20251114-223002.tar.gz` - Pełny backup /var/lib/homebridge
- `zigbee2mqtt-backup-20251114-223002.tar.gz` - Pełny backup /opt/zigbee2mqtt/data

### Pliki konfiguracyjne
- `homebridge-config.json` - Konfiguracja Homebridge
- `zigbee2mqtt-config.yaml` - Konfiguracja Zigbee2MQTT

## Historia zmian

### 2025-11-14
- Upgrade Debian 11 → 12 (Bookworm)
- Upgrade Node.js 20 → 22
- Upgrade npm 10.9.4 → 11.6.2
- Rebuild Homebridge dla Node.js v22
- Naprawa Mosquitto MQTT (wykomentowano pid_file)
- Utworzenie pełnych backupów

## Urządzenia Zigbee

- Czujnik temperatury jadalnia
- Regulator kaloryfer jadalnia
- Czujnik temperatury łazienka góra
- Regulator kaloryfer sypialnia
- Czujnik temperatury hall
- Czujnik temperatury garaż
- Regulator kaloryfer biuro
- Regulator kaloryfer pokój Patryka
- Czujnik ruchu łazienka dół
- Włącznik brama garażowa

## Przywracanie z backupu

### Homebridge
```bash
sudo systemctl stop homebridge
sudo rm -rf /var/lib/homebridge
sudo tar -xzf homebridge-backup-20251114-223002.tar.gz -C /var/lib/
sudo systemctl start homebridge
```

### Zigbee2MQTT
```bash
sudo systemctl stop zigbee2mqtt
sudo rm -rf /opt/zigbee2mqtt/data
sudo tar -xzf zigbee2mqtt-backup-20251114-223002.tar.gz -C /opt/zigbee2mqtt/
sudo systemctl start zigbee2mqtt
```

## Notatki

- System zaktualizowany 2025-11-14
- Wszystkie serwisy działają poprawnie
- Frontend Zigbee2MQTT bez zabezpieczenia hasłem (próba dodania auth zakończyła się błędem YAML)
