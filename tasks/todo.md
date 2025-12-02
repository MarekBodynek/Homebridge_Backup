# Upgrade Debian 12 (bookworm) → Debian 13 (trixie) na Orange Pi

## Plan

- [x] 1. Backup konfiguracji (Pi-hole, Homebridge, Tailscale, crontab)
- [ ] 2. Aktualizacja obecnego systemu (`apt update && apt upgrade`)
- [ ] 3. Zmiana sources.list z `bookworm` na `trixie`
- [ ] 4. Aktualizacja listy pakietów (`apt update`)
- [ ] 5. Upgrade systemu (`apt full-upgrade`)
- [ ] 6. Restart systemu
- [ ] 7. Weryfikacja usług (Pi-hole, Homebridge, Tailscale, Unbound)
- [ ] 8. Weryfikacja wersji systemu

## Uwagi
- **Zaplanowano automatycznie na 2:00 w nocy**
- Skrypt: `/home/orangepi/upgrade-to-trixie.sh`
- Log: `/var/log/trixie-upgrade.log`
- Backup: `~/backup-before-trixie-20251201/`
- Jednorazowe wykonanie (skrypt usuwa się z crona)

## Review

### ✅ UPGRADE ZAKOŃCZONY POMYŚLNIE (2025-12-02)

**System:**
- Debian 13 (trixie)
- Kernel: 4.9.170-sun50iw9
- Upgrade wykonany o ~2:00, restart ~2:07

**Serwisy - wszystkie aktywne:**
- pihole-FTL ✅
- unbound ✅
- homebridge ✅
- tailscaled ✅

**Do naprawienia:**
- Drobny błąd uprawnień: /etc/pihole/versions
