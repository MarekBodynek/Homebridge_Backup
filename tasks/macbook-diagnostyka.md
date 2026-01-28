# Diagnostyka MacBook Pro - 2025-01-24

## Specyfikacja sprzętu

| Parametr | Wartość | Status |
|----------|---------|--------|
| Model | MacBook Pro 18,3 (2021) | - |
| Chip | Apple M1 Pro (10 cores) | OK |
| RAM | 32 GB | OK |
| SSD | 1 TB Apple AP1024R | OK |
| SMART | Verified | OK |
| Bateria | 82% pojemności, 402 cykle | Normalna degradacja |

---

## Diagnoza problemów

### 1. Ekstremalnie wysoki Load Average

| Metryka | Wartość początkowa | Po naprawach | Norma |
|---------|-------------------|--------------|-------|
| Load Average | **331** | 104 | <10 |
| Procesy | 850 | 651 | 300-400 |
| Running | 113 | 35 | 1-5 |

**Główne przyczyny:**
- Google Drive (103% CPU) - masowa synchronizacja
- Chrome (80% CPU) - 39 procesów/kart
- Procesy kontaktów (45% CPU) - ciągła synchronizacja iCloud
- Logitech Options (30% CPU) - sprawdzanie aktualizacji
- Siri/suggestd (33% CPU) - sugestie w tle
- CalendarWidgetExtension (68% CPU) - widgety kalendarza

### 2. Zbyt wiele aplikacji startowych (8)

| Aplikacja | Problem | Rekomendacja |
|-----------|---------|--------------|
| Google Drive | Ciągła synchronizacja | Wyłącz z autostartu |
| Dropbox | 3 agenty w tle | Wyłącz z autostartu |
| OneDrive | Kolejna chmura | Wyłącz jeśli nie używasz |
| NordVPN | OK | Zostaw |
| Bartender 6 | 10% CPU | Rozważ wyłączenie |
| AlDente | OK | Zostaw (chroni baterię) |
| Tailscale | OK | Zostaw |
| MacWhisper | OK | Zostaw |

### 3. LaunchAgents (12 agentów)

```
- ai.perplexity.xpc.plist
- com.dropbox.DropboxUpdater.wake.plist
- com.dropbox.dropboxmacupdate.agent.plist
- com.dropbox.dropboxmacupdate.xpcservice.plist
- com.google.GoogleUpdater.wake.plist
- com.google.keystone.agent.plist
- com.google.keystone.xpcservice.plist
- com.macpaw.CleanMyMac4.Updater.plist
- com.user.contacts-sync.plist (utworzony dzisiaj)
```

### 4. Wykorzystanie dysku

| Folder | Rozmiar | Uwagi |
|--------|---------|-------|
| Mobile Documents (iCloud) | 49 GB | Duże |
| Application Support | 28 GB | Normalne |
| CloudStorage | 25 GB | Google Drive + OneDrive |
| Developer | 13 GB | Xcode? |
| Caches | 5.2 GB | Można wyczyścić |
| Google DriveFS | 1.1 GB | Cache Drive |

**Całkowite wykorzystanie:** 692 GB / 926 GB (77%)

---

## Wykonane naprawy

1. **Wyłączone procesy kontaktów** - synchronizacja raz na godzinę zamiast ciągle
2. **Wyłączony Spotlight indexing** - `sudo mdutil -a -i off`
3. **Wyłączona Siri** - `launchctl disable`
4. **Zamknięty Chrome** - 39 procesów
5. **Zatrzymany Google Drive** - 103% CPU
6. **Wyłączony Logitech Options** - ciągle się respawnował
7. **Wyłączony CleanMyMac monitoring** - 15% CPU

---

## Rekomendacje optymalizacyjne

### KRYTYCZNE (zrób natychmiast)

1. **Wyłącz AirPlay Receiver**
   ```
   System Settings → General → AirDrop & Handoff → AirPlay Receiver: OFF
   ```
   Oszczędność: ~20% CPU

2. **Usuń widgety kalendarza z pulpitu/Notification Center**
   - CalendarWidgetExtension zjada 68% CPU

3. **Usuń Logitech Options** (jeśli nie używasz myszy/klawiatury Logitech)
   ```bash
   # Lub wyłącz na stałe:
   sudo launchctl bootout system/com.logitech.optionsplus.updater
   ```

4. **Ogranicz aplikacje chmurowe** - masz 3 aktywne:
   - Google Drive
   - Dropbox
   - OneDrive

   Wybierz jedną i wyłącz pozostałe z autostartu.

### ZALECANE (w najbliższym czasie)

5. **Wyczyść cache** (~5 GB)
   ```bash
   rm -rf ~/Library/Caches/*
   ```

6. **Usuń zbędne LaunchAgents**
   ```bash
   # Wyłącz Perplexity background
   launchctl unload ~/Library/LaunchAgents/ai.perplexity.xpc.plist

   # Wyłącz CleanMyMac updater
   launchctl unload ~/Library/LaunchAgents/com.macpaw.CleanMyMac4.Updater.plist
   ```

7. **Ogranicz karty Chrome** - używaj max 10-15 kart

8. **Włącz Spotlight z wyłączeniami**
   ```bash
   # Włącz Spotlight
   sudo mdutil -a -i on

   # Wyklucz foldery w: System Settings → Siri & Spotlight → Privacy
   # Dodaj: ~/Library, ~/CloudStorage, /Applications
   ```

### OPCJONALNE (dla maksymalnej wydajności)

9. **Wyłącz animacje**
   ```bash
   defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
   defaults write com.apple.dock autohide-time-modifier -float 0
   defaults write com.apple.dock autohide-delay -float 0
   killall Dock
   ```

10. **Restart co tydzień** - macOS kumuluje procesy w tle

---

## Bateria - stan

| Metryka | Wartość | Ocena |
|---------|---------|-------|
| Pojemność | 82% | Normalna degradacja |
| Cykle | 402 | ~50% życia (do 1000) |
| Kondycja | Normal | OK |

**Rekomendacja:** AlDente chroni baterię - zostaw włączone.

---

## Podsumowanie

**Główny problem:** Zbyt wiele aplikacji synchronizujących w tle (Google Drive, Dropbox, OneDrive, iCloud) + Chrome z wieloma kartami.

**Rozwiązanie:** Ogranicz do jednej chmury, zamykaj Chrome gdy nie używasz, usuń widgety kalendarza.

**Po optymalizacji Load Average powinien być:** 2-5 (obecnie 104)
