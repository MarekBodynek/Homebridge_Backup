# Lista zadań

> **Uwaga:** Szczegółowa dokumentacja infrastruktury znajduje się w [README.md](../README.md)

---

## Aktywne zadania

### ClawdBot Gateway - diagnoza problemu (2026-02-02)

**Problem:** ClawdBot (Claudia) nie działa

**Plan diagnozy:**
- [x] Połączyć się SSH z RPi (192.168.0.188)
- [x] Sprawdzić status usługi clawdbot-gateway
- [x] Sprawdzić logi systemd
- [x] Zidentyfikować problem
- [x] Naprawić

**Wyniki diagnozy:**
- ✅ Serwis clawdbot-gateway: **DZIAŁA** (active since 03:00:15, 9h uptime)
- ✅ Porty nasłuchują:
  - 18789: clawdbot-gateway (localhost)
  - 3001: clawd-api-server (wszystkie interfejsy)
- ✅ Procesy ClawdBot działają prawidłowo
- ✅ Telegram włączony (bot token: 7744778976:AAE...)
- ✅ BlueBubbles włączony (https://bluebubbles.bodino.us.kg)
- ✅ Telegram bot API: token działa poprawnie
- ✅ ID użytkownika (1030820489) na liście dozwolonych

**Problem:** Telegram - bot nie odpowiada na wiadomości

**Rozwiązanie:**
- ✅ Wykonano restart ClawdBot Gateway (12:15:11)

**Status:** ✅ **NAPRAWIONO** - Claudia odpowiada na Telegramie

---

### Tunel claudia.bodino.us.kg - naprawa i monitoring (2026-02-02)

**Problem:** https://claudia.bodino.us.kg/api/documents zwracał błąd 502 Bad Gateway

**Diagnoza:**
- Tunel Cloudflare działał poprawnie (claudia.bodino.us.kg → localhost:3001)
- Serwer `clawd-api-server.js` nie działał - port 3001 nie nasłuchiwał
- Serwer zatrzymał się po restarcie ClawdBot Gateway

**Rozwiązanie:**
1. ✅ Uruchomiono clawd-api-server: `cd /home/bodino && nohup node clawd-api-server.js > /tmp/clawd-api.log 2>&1 &`
2. ✅ Dodano monitoring do `/usr/local/bin/check-tunnels.sh`:
   - Sprawdza URL https://claudia.bodino.us.kg/api/documents
   - Automatycznie restartuje clawd-api-server gdy nie odpowiada
3. ✅ Przetestowano skrypt - działa poprawnie

**Status:** ✅ **NAPRAWIONO** + dodano do automatycznego monitorowania (cron co 5 min)

---

## Review - ClawdBot Gateway (2026-02-02)

**Problem:** Claudia nie odpowiadała na wiadomości Telegram

**Diagnoza:**
- Serwis działał prawidłowo (active, 9h uptime)
- Token Telegram ważny, API odpowiadało
- Użytkownik na liście dozwolonych
- Porty nasłuchiwały poprawnie

**Rozwiązanie:**
Restart ClawdBot Gateway - problem z sesją lub połączeniem Telegram

**Czas naprawy:** ~15 minut

**Wnioski:**
Jeśli Claudia przestaje odpowiadać na Telegramie, najpierw sprawdzić status serwisu, a następnie wykonać restart. Problem prawdopodobnie związany z utratą połączenia z Telegram API podczas długiego działania serwisu

---

### ClawdBot Gateway - diagnoza i naprawa (2025-01-29)

**Problem:** ClawdBot przestał działać na Raspberry Pi

**Plan diagnozy i naprawy:**
- [x] 1. Połączyć się SSH z RPi (192.168.0.188)
- [x] 2. Sprawdzić status usługi ClawdBot Gateway
- [x] 3. Przeczytać logi systemd (ostatnie 50 wpisów)
- [x] 4. Zweryfikować port 18789 (czy nasłuchuje)
- [x] 5. Zidentyfikować przyczynę błędu
- [x] 6. Naprawić problem
- [x] 7. Zrestartować usługę
- [x] 8. Zweryfikować, że działa poprawnie

**Przyczyna błędu:**
ClawdBot Gateway nie mógł się uruchomić, ponieważ w pliku usługi systemd brakło zmiennych środowiskowych:
- `ELEVENLABS_API_KEY` - API key dla text-to-speech
- `TELEGRAM_BOT_TOKEN` - token bota Telegram
- `BLUEBUBBLES_PASSWORD` - hasło do BlueBubbles
- `CLAWDBOT_GATEWAY_TOKEN` - był ustawiony na `undefined`

To powodowało nieskończoną pętlę błędów - ClawdBot próbował się uruchomić, padał z błędem o brakującej zmiennej, systemd restartował go co 5 sekund, generując setki tysięcy logów (14-17 tys. na minutę!). Systemd-journald stłumił ponad 500,000 wiadomości.

**Rozwiązanie:**
1. Znaleziono plik `~/.secrets/api-keys.env` zawierający wszystkie potrzebne tokeny
2. Dodano sourcowanie pliku do `~/.bashrc`
3. Ręcznie zaktualizowano plik `~/.config/systemd/user/clawdbot-gateway.service`, dodając wszystkie zmienne Environment
4. Przeładowano konfigurację systemd i uruchomiono usługę
5. Zweryfikowano poprawne działanie - usługa działa na porcie 18789

**Status:** ✅ Naprawiono - ClawdBot Gateway działa poprawnie

---

### ClawdBot Memory Search - naprawa (2026-02-01)

**Problem:** Memory search nie działał - zwracał puste wyniki, embedding indeksowanie failowało z błędem "Input is longer than the context size"

**Diagnoza:**
- Model embeddings `gte-large_fp32.gguf` miał za mały context size (~128 tokenów)
- Nawet pliki podzielone na 200-liniowe fragmenty były za duże
- Błąd występował przy każdej próbie indeksowania

**Rozwiązanie:**
1. ✅ Pobrано nowy model embeddings: `nomic-embed-text-v1.5.f16.gguf`
   - Context size: **8192 tokenów** (64x większy!)
   - Rozmiar: 262MB (vs 1.3GB stary model)
   - Źródło: HuggingFace (nomic-ai/nomic-embed-text-v1.5-GGUF)
2. ✅ Zaktualizowano konfigurację w `~/.clawdbot/clawdbot.json`
3. ✅ Zaindeksowano wszystkie pliki memory: **9/9 plików, 33 chunki**
4. ✅ Przetestowano wyszukiwanie - działa poprawnie z scoringiem
5. ✅ Poinformowano Claudię (MEMORY.md + MEMORY-FIXED-URGENT.md)

**Status:** ✅ W pełni działający - Memory search gotowy do użycia

**Czas naprawy:** ~45 minut

---

### ClawdBot Memory - Smart Fallback System (2026-02-01 23:30)

**Ewolucja modeli embeddings:**
- v1: gte-large_fp32 (128 tokenów) → failował na małych plikach
- v2: nomic-embed-text-v1.5 (8K tokenów) → działał dla aktualnych plików
- v3: Qwen3-Embedding-8B (32K tokenów) → duży model dla przyszłości
- **v4: Smart Fallback System** → nomic primary + auto-switch do Qwen3

**Powód smart fallback:**
- Qwen3 duży (7.5GB) i wolniejszy niż nomic (262MB)
- Nomic wystarczy dla 99% przypadków (do ~2000 linii)
- Automatyczne przełączanie tylko gdy potrzeba

**Implementacja:**
1. ✅ Skrypt `~/memory-smart-index.sh` (RPi):
   - Pre-check rozmiaru wszystkich plików memory
   - <2000 linii → nomic (szybki, lekki)
   - >2000 linii → automatyczne przełączenie na Qwen3
   - Restart ClawdBot Gateway i ponowne indeksowanie
2. ✅ Oba modele zainstalowane i gotowe:
   - Primary: nomic-embed-text-v1.5.f16.gguf (262MB)
   - Fallback: Qwen3-Embedding-8B-Q8_0.gguf (7.5GB)
3. ✅ Przywrócono nomic jako primary model
4. ✅ Zaktualizowano dokumentację (credentials.md, MEMORY.md)

**Status aktualny:**
- Model: nomic-embed-text-v1.5.f16.gguf
- Indexed: 9/9 plików · 65 chunks
- Vector search: ready
- Smart fallback: gotowy do użycia

**Workflow:**
```bash
# Zamiast: clawdbot memory index
# Użyj:
~/memory-smart-index.sh
```

**Status:** ✅ System wdrożony i działający

---

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

### 2026-02-01: ClawdBot & MS365 Recovery

**Zmienne model na Sonnet:**
- ✅ ClawdBot primary model: `anthropic/claude-sonnet-4-5`
- ✅ Claude Code settings: `model: "sonnet"`
- ✅ ClawdBot Gateway zrestartowany i działa

**MS365 MCP Server - Recovery:**
- ✅ Znaleziono wszystkie pliki konfiguracji na RPi
- ✅ Service ms365-mcp.service aktywny na porcie 3365
- ✅ Token refresh script działa (auto co 45 min)
- ✅ Daemon reload wykonany
- ✅ Pliki znajdują się w:
  - `~/.config/systemd/user/ms365-mcp.service`
  - `~/ms365-refresh-token.sh`
  - `~/ms365-token.json`
  - `~/.clawdbot/ms365-cli.py`

**ByteRover - automatyczna kuracja kontekstu:**
- ✅ Skonfigurowany globalnie dla wszystkich projektów
- ✅ Auto-init w hook `export-to-byterover.sh`
- ✅ Team: Marek_team, Space: Marek_Space
- ✅ Autocompact włączony (hook PreCompact)
- ✅ Projekt homebridge-backup zainicjalizowany
- ✅ `.brv/` dodany do `.gitignore`

**MS365 Graph API - integracja:**
- ✅ Dodano uprawnienie Mail.ReadWrite.Shared w Azure AD
- ✅ Admin consent udzielony
- ✅ Token odświeżony z nowymi uprawnieniami
- ✅ Utworzono kompletny przewodnik: `docs/ms365-graph-api-setup.md`
- ⚠️ Dostęp do shared mailboxów wymaga delegacji (vzdrzevanje@kea.si)

**ClawdBot - zmiana profilu na prywatny (2026-02-01):**
- ✅ Przywrócono profil `anthropic:claudia` w clawdbot.json
- ✅ Przywrócono profil w auth-profiles.json z tokenem OAuth
- ✅ Ustawiono lastGood.anthropic na "anthropic:claudia"
- ✅ ClawdBot Gateway zrestartowany - używa profilu prywatnego
- ✅ Model pozostaje Sonnet (anthropic/claude-sonnet-4-5)
- ✅ **Fix (2026-02-01 22:19):** Naprawiono crash loop (491 restartów)
  - Przyczyna: nierozpoznane klucze w `memorySearch.chunking`
  - Rozwiązanie: `clawdbot doctor --fix`
  - Status: Gateway działa stabilnie

---

### 2025-12-05: Reinstalacja Orange Pi
- Przywracanie po awarii karty SD
- Upgrade do Debian 13 (Trixie)
