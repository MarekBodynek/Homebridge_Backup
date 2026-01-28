# Migracja Raspberry Pi na SSD NVMe

## Status: ZAPLANOWANE

**Planowana data:** ~koniec grudnia 2025
**Sprzęt:** HAT NVMe + dysk SSD NVMe

---

## Wymagania sprzętowe

- [ ] Dysk SSD NVMe 2TB (M.2)
- [ ] HAT NVMe dla Raspberry Pi 5
- [ ] Śrubki montażowe (zwykle w zestawie z HAT)
- [ ] Zasilacz 5V/5A (zalecany dla stabilności z NVMe)
- [ ] Pad USB/Bluetooth (do gier)
- [ ] Kabel HDMI (do grania na TV)

---

## Plan migracji

### Faza 1: Przygotowanie (przed migracją)

- [ ] 1. Wykonać pełny backup systemu (dd image)
- [ ] 2. Zaktualizować system do najnowszej wersji
- [ ] 3. Zaktualizować bootloader EEPROM:
  ```bash
  sudo rpi-eeprom-update -a
  sudo reboot
  ```

### Faza 2: Montaż sprzętu

- [ ] 4. Wyłączyć Raspberry Pi
- [ ] 5. Zamontować HAT na GPIO
- [ ] 6. Zainstalować dysk SSD w HAT
- [ ] 7. Uruchomić Raspberry Pi (z karty SD)

### Faza 3: Konfiguracja boot z NVMe/SATA

- [ ] 8. Sprawdzić czy dysk jest widoczny:
  ```bash
  lsblk
  # Powinien być widoczny jako /dev/nvme0n1 (NVMe) lub /dev/sda (SATA)
  ```

- [ ] 9. Ustawić boot order na NVMe/USB:
  ```bash
  sudo raspi-config
  # Advanced Options → Boot Order → NVMe/USB Boot
  ```

### Faza 4: Klonowanie systemu

- [ ] 10. Zainstalować rpi-clone:
  ```bash
  sudo apt install git
  git clone https://github.com/billw2/rpi-clone.git
  cd rpi-clone && sudo cp rpi-clone /usr/local/bin/
  ```

- [ ] 11. Sklonować system na SSD NVMe:
  ```bash
  sudo rpi-clone nvme0n1 -f
  ```

- [ ] 12. Poczekać na zakończenie klonowania (~15-30 min)

### Faza 5: Uruchomienie z SSD

- [ ] 13. Wyłączyć Raspberry Pi
- [ ] 14. Wyjąć kartę SD
- [ ] 15. Uruchomić Raspberry Pi (boot z SSD)

### Faza 6: Weryfikacja

- [ ] 16. Sprawdzić boot z SSD:
  ```bash
  lsblk
  # Root (/) powinien być na nvme0n1p2 lub sda2

  df -h
  # Sprawdzić rozmiar partycji
  ```

- [ ] 17. Rozszerzyć partycję na pełny rozmiar SSD:
  ```bash
  sudo raspi-config
  # Advanced Options → Expand Filesystem
  sudo reboot
  ```

- [ ] 18. Sprawdzić wszystkie serwisy:
  ```bash
  systemctl status cloudflared n8n pihole-FTL unbound tailscaled
  ```

- [ ] 19. Przetestować dostęp zewnętrzny:
  - https://n8n.bodino.us.kg
  - https://rpi-ssh.bodino.us.kg
  - Pi-hole dashboard

### Faza 7: Migracja Home Assistant z Mac Mini

- [ ] 20. Zainstalować Home Assistant Supervised lub Container:
  ```bash
  # Opcja 1: Docker (zalecane)
  sudo apt install docker.io docker-compose
  docker run -d --name homeassistant --restart=unless-stopped \
    -v /home/bodino/homeassistant:/config \
    -e TZ=Europe/Warsaw \
    --network=host \
    ghcr.io/home-assistant/home-assistant:stable
  ```

- [ ] 21. Przenieść konfigurację z Mac Mini:
  ```bash
  scp -r marekbodynek@192.168.0.106:~/.homeassistant/* ~/homeassistant/
  ```

- [ ] 22. Zaktualizować Cloudflare Tunnel (ha.bodino.us.kg → RPi:8123)

- [ ] 23. Wyłączyć HA na Mac Mini

### Faza 8: Instalacja RetroArch

- [ ] 24. Zainstalować RetroArch:
  ```bash
  sudo apt update
  sudo apt install retroarch retroarch-assets libretro-*
  ```

- [ ] 25. Zainstalować dodatkowe emulatory:
  ```bash
  sudo apt install dolphin-emu mame mednafen vice fs-uae hatari stella fuse-emulator-sdl dosbox
  ```

- [ ] 26. Skonfigurować SMB mount dla ROMów z Mac Mini

- [ ] 27. Skonfigurować pad i przetestować gry

### Faza 9: Cleanup

- [ ] 28. Zachować kartę SD jako backup awaryjny
- [ ] 29. Zaktualizować dokumentację (README.md)
- [ ] 30. Wykonać pierwszy backup z SSD

---

## Serwisy do zweryfikowania po migracji

| Serwis | Komenda sprawdzająca | Status |
|--------|---------------------|--------|
| Pi-hole | `pihole status` | [ ] |
| Unbound | `dig @127.0.0.1 -p 5335 google.com` | [ ] |
| Cloudflared | `systemctl status cloudflared` | [ ] |
| n8n | `curl -s localhost:5678` | [ ] |
| Tailscale | `tailscale status` | [ ] |
| Home Assistant | `docker ps \| grep homeassistant` | [ ] |
| RetroArch | `retroarch --version` | [ ] |

---

## Porównanie wydajności

| Parametr | Karta SD | SSD NVMe (szacowane) |
|----------|----------|----------------------|
| **Odczyt sekwencyjny** | ~45 MB/s | ~800+ MB/s |
| **Zapis sekwencyjny** | ~20 MB/s | ~600+ MB/s |
| **IOPS (4K random)** | ~2,000 | ~100,000+ |
| **Czas boot** | ~25 sek | ~8 sek |
| **Żywotność** | 1-2 lata | 5-10 lat |

*Uwaga: Prędkości NVMe ograniczone przez PCIe 2.0 x1 w Raspberry Pi 5 (~500 MB/s teoretyczne max)*

---

## Troubleshooting

### Problem: Raspberry Pi nie bootuje z SSD
**Rozwiązanie:**
1. Włóż kartę SD i uruchom system
2. Sprawdź bootloader: `sudo rpi-eeprom-update`
3. Sprawdź boot order: `sudo raspi-config`
4. Sprawdź czy SSD jest widoczny: `lsblk`

### Problem: SSD nie jest widoczny
**Rozwiązanie:**
1. Sprawdź podłączenie HAT
2. Sprawdź zasilanie (SSD wymaga więcej prądu)
3. Użyj zasilacza 5V/3A minimum

### Problem: Serwisy nie działają po migracji
**Rozwiązanie:**
1. Sprawdź logi: `journalctl -xe`
2. Zrestartuj serwisy: `sudo systemctl restart <service>`
3. Sprawdź uprawnienia plików

---

## Notatki

- Karta SD może pozostać jako backup awaryjny
- Po migracji backup-servers.sh będzie tworzył obrazy z SSD (większe pliki)
- Rozważyć zmianę retencji backupów (SSD = większe obrazy)
