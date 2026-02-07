# OpenClaw Failover — Mac Studio ↔ Raspberry Pi

**Data:** 2026-02-07  
**Status:** ✅ Przetestowane i działające

---

## Architektura

```
🖥️ Mac Studio (PRIMARY)          🍓 RPi 5 (STANDBY)
   192.168.0.199                     192.168.0.188
   ┌─────────────────┐               ┌─────────────────┐
   │ OpenClaw Gateway │◄── SSH ──────│ Watchdog (cron)  │
   │ port 18789       │   health     │ co 2 min         │
   │ (loopback)       │   check      │                  │
   ├─────────────────┤               ├─────────────────┤
   │ PostgreSQL 17    │── logical ──►│ PostgreSQL 17    │
   │ memu (publisher) │  replication │ memu (subscriber)│
   │ 1256 memories    │  real-time   │ replika          │
   ├─────────────────┤               ├─────────────────┤
   │ Telegram Bot     │              │ Telegram Bot     │
   │ (aktywny)        │              │ (standby)        │
   └─────────────────┘               └─────────────────┘
```

---

## Monitoring

**Watchdog:** `~/bin/openclaw-watchdog.sh` (na RPi)  
**Cron:** `*/2 * * * * ~/bin/openclaw-watchdog.sh`  
**Metoda:** SSH z RPi → Mac Studio → `curl localhost:18789`  

**Co wykrywa:**
- ⚡ Zanik zasilania (SSH fail)
- 💀 Gateway crash (curl fail)
- 🔌 Problem z siecią (SSH timeout)

---

## Scenariusz awarii

```
T+0:00   Mac Studio pada
T+0:30   Watchdog: pierwsze sprawdzenie → FAIL
T+0:40   Watchdog: retry po 10s → FAIL
T+0:40   Stan: primary → failover
T+0:48   RPi: openclaw gateway start (systemctl)
T+0:53   Fallback: direct node start (jeśli systemctl fail)
T+0:55   RPi: Gateway działa ✅
T+1:00   Telegram: notyfikacja "Mac Studio OFFLINE, RPi przejmuje"
T+2:00   RPi: obsługuje Telegram bota
```

**Czas do przejęcia: ~1-3 minuty**

---

## Scenariusz powrotu

```
T+0:00   Mac Studio wraca online
T+0:30   Watchdog: sprawdzenie → Studio odpowiada!
T+0:31   Sync-back: porównanie count memory_items/resources
T+0:32   Sync-back: nowe rekordy RPi → Mac Studio (jeśli są)
T+0:33   Sync-back: rsync memory/*.md + MEMORY.md
T+0:35   RPi: openclaw gateway stop
T+0:40   Stan: failover → primary
T+0:41   Telegram: notyfikacja "Mac Studio ONLINE, powrót"
```

**Czas do powrotu: ~1-2 minuty**

---

## Replikacja danych

### PostgreSQL Logical Replication (real-time)

| Parametr | Mac Studio (Publisher) | RPi (Subscriber) |
|----------|----------------------|------------------|
| Wersja PG | 17 (Homebrew) | 17 (Docker pgvector) |
| Port | 5432 | 5433 |
| Baza | memu | memu |
| Publication | memu_pub | — |
| Subscription | — | memu_sub |
| Tabele | ALL (5 tabel) | replika |
| Kierunek | → RPi (real-time) | ← Studio (sync-back) |

**Tabele replikowane:**
- `memory_items` (wspomnienia)
- `resources` (zasoby)
- `memory_categories` (kategorie)
- `category_items` (powiązania)
- `alembic_version` (migracje)

### Sync-back przy powrocie

**Skrypt:** `~/bin/memu-syncback.sh` (na RPi)

1. Porównuje `count(*)` na obu stronach
2. Jeśli RPi ma więcej → dump + restore na Studio
3. `rsync` plików workspace (memory/*.md, MEMORY.md)

### Pliki workspace

| Plik | Sync |
|------|------|
| `memory/*.md` | rsync --update (RPi → Studio) |
| `MEMORY.md` | rsync --update (RPi → Studio) |

---

## Notyfikacje Telegram

| Zdarzenie | Emoji | Treść |
|-----------|-------|-------|
| Failover | 🚨 | "OpenClaw na Mac Studio OFFLINE — RPi przejmuje!" |
| Powrót | 🖥️ | "Mac Studio ONLINE — pamięć zsync, RPi zatrzymany" |
| Fail | 🚨 | "FAILOVER FAILED — RPi nie mógł wystartować!" |

---

## Pliki konfiguracyjne

### RPi

| Plik | Opis |
|------|------|
| `~/bin/openclaw-watchdog.sh` | Watchdog z SSH health check |
| `~/bin/memu-syncback.sh` | Sync pamięci RPi → Studio |
| `~/.openclaw/openclaw.json` | Config OpenClaw (kopia ze Studio) |
| `/tmp/openclaw-watchdog-state` | Stan: `primary` lub `failover` |
| `/tmp/openclaw-watchdog.log` | Logi watchdoga |

### Mac Studio

| Plik | Opis |
|------|------|
| `~/.openclaw/openclaw.json` | Główny config |
| `/opt/homebrew/var/postgresql@17/postgresql.conf` | `wal_level=logical` |
| `/opt/homebrew/var/postgresql@17/pg_hba.conf` | Dostęp LAN dla replikacji |

### Cron (RPi)

```
*/2 * * * * /home/bodino/bin/openclaw-watchdog.sh
```

---

## Wymagania

- SSH key: RPi → Mac Studio (bodino → marekbodynek)
- SSH key: Mac Studio → RPi (marekbodynek → bodino)
- PostgreSQL 17 na obu maszynach
- OpenClaw 2026.2.6+ na obu maszynach
- `curl` na Mac Studio (dla health check)

---

## Testy (2026-02-07)

| Test | Czas | Wynik |
|------|------|-------|
| #1 (15:20) | Gateway stop → RPi przejął po ~9s | ✅ 22 min failover, auto-powrót |
| #2 (15:44) | Gateway stop → RPi przejął po ~13s | ✅ Auto-powrót + sync |

---

## Troubleshooting

**Watchdog nie startuje gateway:**
```bash
# Sprawdź DBUS (potrzebne dla systemctl --user z crona)
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"
export XDG_RUNTIME_DIR="/run/user/1000"
openclaw gateway start
```

**Replikacja nie działa:**
```bash
# Na Mac Studio
/opt/homebrew/opt/postgresql@17/bin/psql -d memu -c "SELECT * FROM pg_replication_slots;"

# Na RPi
docker exec memu-postgres psql -U postgres -d memu -c "SELECT * FROM pg_subscription;"
```

**Telegram conflict (409):**
- Normalne przy przełączaniu — nowa instancja przejmuje polling
- Stara dostaje "terminated by other getUpdates request"
- Rozwiązuje się automatycznie w ~5s
