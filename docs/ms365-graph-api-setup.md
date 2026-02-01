# Microsoft Graph API - Przewodnik Integracji

**Ostatnia aktualizacja:** 2026-02-01
**Wersja:** 1.0

Ten dokument opisuje jak skonfigurować dostęp do Microsoft Graph API dla projektów Claude Code / ClawdBot.

---

## Spis treści

1. [Wymagania wstępne](#wymagania-wstępne)
2. [Konfiguracja Azure AD App Registration](#konfiguracja-azure-ad-app-registration)
3. [Generowanie tokenów OAuth](#generowanie-tokenów-oauth)
4. [Integracja z projektem](#integracja-z-projektem)
5. [Uprawnienia (Permissions)](#uprawnienia-permissions)
6. [Testowanie API](#testowanie-api)
7. [Troubleshooting](#troubleshooting)

---

## Wymagania wstępne

- Konto Microsoft 365 (praca/organizacja)
- Dostęp do Azure Portal ([portal.azure.com](https://portal.azure.com))
- Uprawnienia do tworzenia App Registrations (lub administrator musi to zrobić)
- `jq` zainstalowane (do parsowania JSON)

---

## Konfiguracja Azure AD App Registration

### 1. Utwórz nową aplikację

1. Zaloguj się do [Azure Portal](https://portal.azure.com)
2. Wyszukaj "**Rejestracje aplikacji**" (App registrations)
3. Kliknij "**+ Nowa rejestracja**"
4. Wypełnij formularz:
   - **Nazwa:** np. "MyProject MS365 Integration"
   - **Obsługiwane typy kont:** "Konta tylko w tym katalogu organizacyjnym"
   - **Identyfikator URI przekierowania:**
     - Platforma: **Web**
     - URI: `http://localhost:3000/auth/callback` (lub Twój URL)
5. Kliknij "**Zarejestruj**"

### 2. Zapisz ID aplikacji

Po utworzeniu aplikacji, zapisz:
- **Application (client) ID** - będzie potrzebne później
- **Directory (tenant) ID** - identyfikator organizacji

Przykład:
```
Application ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Tenant ID: yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
```

### 3. Utwórz Client Secret

1. W menu aplikacji wybierz "**Certyfikaty i wpisy tajne**" (Certificates & secrets)
2. Kliknij "**+ Nowy wpis tajny klienta**"
3. Dodaj opis (np. "Production secret") i wybierz ważność (zalecane: 24 miesiące)
4. Kliknij "**Dodaj**"
5. **WAŻNE:** Skopiuj wartość sekretu natychmiast - nie będzie już widoczny!

Przykład:
```
Client Secret: zzzzzz~xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## Uprawnienia (Permissions)

### Dodawanie uprawnień

1. W menu aplikacji wybierz "**Uprawnienia interfejsu API**" (API permissions)
2. Kliknij "**+ Dodaj uprawnienie**"
3. Wybierz "**Microsoft Graph**"
4. Wybierz typ uprawnień:
   - **Delegated permissions** - działają w imieniu zalogowanego użytkownika
   - **Application permissions** - działają jako aplikacja (wymaga admin consent)

### Zalecane uprawnienia Delegated

Dla podstawowej integracji z mailami i kalendarzem:

| Uprawnienie | Opis | Kiedy potrzebne |
|-------------|------|-----------------|
| `User.Read` | Odczyt profilu zalogowanego użytkownika | Zawsze (podstawowe) |
| `Mail.Read` | Odczyt własnych wiadomości | Czytanie maili użytkownika |
| `Mail.ReadWrite` | Odczyt i zapis wiadomości | Czytanie + tworzenie/modyfikacja |
| `Mail.Send` | Wysyłanie maili | Wysyłanie wiadomości |
| `Mail.ReadWrite.Shared` | Dostęp do shared mailboxów | Mailboxy udostępnione dla użytkownika |
| `Calendars.Read` | Odczyt kalendarzy | Czytanie wydarzeń |
| `Calendars.ReadWrite` | Odczyt i zapis kalendarzy | Tworzenie wydarzeń |
| `Files.ReadWrite.All` | OneDrive/SharePoint | Dostęp do plików |

### Uprawnienia Application (szeroki dostęp)

**UWAGA:** Wymagają zgody administratora i dają dostęp do wszystkich użytkowników!

| Uprawnienie | Opis | Ostrzeżenie |
|-------------|------|-------------|
| `User.Read.All` | Odczyt wszystkich użytkowników | Dostęp do katalogu organizacji |
| `Mail.Read` (App) | Odczyt wszystkich mailboxów | Dostęp do każdej skrzynki! |
| `Calendars.Read` (App) | Odczyt wszystkich kalendarzy | Dostęp do każdego kalendarza! |

### Udzielenie zgody administratora

Po dodaniu uprawnień **Delegated**, administrator musi udzielić zgody:

1. W "**Uprawnienia interfejsu API**" kliknij "**Udziel zgody administratora dla [Organizacja]**"
2. Potwierdź w oknie dialogowym

**Status** przy każdym uprawnieniu powinien pokazać zielony checkmark ✓

---

## Generowanie tokenów OAuth

### Opcja 1: Interaktywny flow (zalecane dla Delegated permissions)

```bash
# 1. Utwórz URL autoryzacji
TENANT_ID="twoj-tenant-id"
CLIENT_ID="twoj-client-id"
REDIRECT_URI="http://localhost:3000/auth/callback"
SCOPE="User.Read Mail.ReadWrite Calendars.ReadWrite offline_access"

AUTH_URL="https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/authorize?client_id=${CLIENT_ID}&response_type=code&redirect_uri=${REDIRECT_URI}&scope=${SCOPE}&response_mode=query"

echo "Otwórz w przeglądarce:"
echo "$AUTH_URL"

# 2. Po autoryzacji skopiuj 'code' z URL przekierowania
# Przykład: http://localhost:3000/auth/callback?code=AUTHORIZATION_CODE

# 3. Wymień kod na token
AUTHORIZATION_CODE="kod-z-url"
CLIENT_SECRET="twoj-client-secret"

curl -X POST "https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "code=${AUTHORIZATION_CODE}" \
  -d "redirect_uri=${REDIRECT_URI}" \
  -d "grant_type=authorization_code" \
  | jq '.' > token.json

# 4. Token zapisany w token.json
```

### Opcja 2: Refresh token (automatyczne odświeżanie)

```bash
#!/bin/bash
# refresh-token.sh

TOKEN_FILE="$HOME/ms365-token.json"
TENANT_ID="twoj-tenant-id"
CLIENT_ID="twoj-client-id"
CLIENT_SECRET="twoj-client-secret"

# Odczytaj refresh_token
REFRESH_TOKEN=$(jq -r .refresh_token "$TOKEN_FILE")

# Pobierz nowy access_token
curl -s -X POST "https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "refresh_token=${REFRESH_TOKEN}" \
  -d "grant_type=refresh_token" \
  -d "scope=User.Read Mail.ReadWrite Calendars.ReadWrite offline_access" \
  | jq '.' > "$TOKEN_FILE.new"

# Zachowaj refresh_token (API może nie zwrócić nowego)
OLD_REFRESH=$(jq -r .refresh_token "$TOKEN_FILE")
NEW_REFRESH=$(jq -r .refresh_token "$TOKEN_FILE.new")

if [ "$NEW_REFRESH" = "null" ]; then
  jq --arg rt "$OLD_REFRESH" '.refresh_token = $rt' "$TOKEN_FILE.new" > "$TOKEN_FILE"
else
  mv "$TOKEN_FILE.new" "$TOKEN_FILE"
fi

echo "Token odświeżony: $TOKEN_FILE"
```

### Automatyczne odświeżanie (cron)

```bash
# Dodaj do crontab (odświeżanie co 45 minut)
*/45 * * * * /path/to/refresh-token.sh >> /var/log/ms365-refresh.log 2>&1
```

---

## Integracja z projektem

### Struktura plików

```
twoj-projekt/
├── .env                    # Zmienne środowiskowe (NIE commitować!)
├── ms365-token.json        # OAuth token (NIE commitować!)
├── refresh-token.sh        # Skrypt odświeżania
└── docs/
    └── ms365-api-guide.md  # Ten dokument
```

### Plik .env

```bash
# MS365 Graph API Configuration
MS365_TENANT_ID=yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
MS365_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
MS365_CLIENT_SECRET=zzzzzz~xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
MS365_TOKEN_FILE=/path/to/ms365-token.json
```

### .gitignore

```gitignore
# MS365 Credentials
.env
ms365-token.json
*.secret
```

---

## Testowanie API

### Test 1: Odczyt profilu użytkownika

```bash
TOKEN=$(jq -r .access_token ms365-token.json)

curl -s -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/me" \
  | jq '{displayName, mail, userPrincipalName}'
```

**Oczekiwany wynik:**
```json
{
  "displayName": "Jan Kowalski",
  "mail": "jan.kowalski@firma.pl",
  "userPrincipalName": "jan.kowalski@firma.pl"
}
```

### Test 2: Lista wiadomości (10 najnowszych)

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/me/messages?\$top=10&\$select=subject,from,receivedDateTime" \
  | jq '.value[] | {subject, from: .from.emailAddress.address, received: .receivedDateTime}'
```

### Test 3: Lista wydarzeń w kalendarzu (następne 7 dni)

```bash
START_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
END_DATE=$(date -u -d "+7 days" +"%Y-%m-%dT%H:%M:%SZ")

curl -s -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/me/calendar/calendarView?startDateTime=$START_DATE&endDateTime=$END_DATE" \
  | jq '.value[] | {subject, start: .start.dateTime, end: .end.dateTime}'
```

### Test 4: Wysłanie wiadomości

```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "subject": "Test z Graph API",
      "body": {
        "contentType": "Text",
        "content": "To jest testowa wiadomość wysłana przez Microsoft Graph API."
      },
      "toRecipients": [
        {
          "emailAddress": {
            "address": "odbiorca@domena.pl"
          }
        }
      ]
    }
  }' \
  "https://graph.microsoft.com/v1.0/me/sendMail"
```

---

## Praca z Shared Mailboxami

### Wymagane uprawnienia

- `Mail.ReadWrite.Shared` (Delegated)

### Warunki dostępu

Shared mailbox musi być **explicite udostępniony** dla Twojego konta:

**Opcja A - Delegacja w Outlook:**
1. Właściciel mailboxa: Outlook → Settings → Accounts → Delegation
2. Dodaje Ciebie jako delegata

**Opcja B - Administrator konfiguruje Shared Mailbox:**
1. Admin Center → Users → Shared mailboxes
2. Dodaje Cię jako członka shared mailboxa

### Odczyt wiadomości z shared mailboxa

```bash
# Po udostępnieniu, shared mailboxy pojawią się w /me/mailFolders
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/me/mailFolders" \
  | jq '.value[] | {displayName, id}'

# Odczyt wiadomości z konkretnego folderu
FOLDER_ID="AAMkAGI2T..."
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/me/mailFolders/$FOLDER_ID/messages?\$top=10" \
  | jq '.value[] | {subject, from: .from.emailAddress.address}'
```

---

## Claude Code - Konfiguracja w projekcie

### Dodaj do context file

Utwórz plik `.claude/project-context.md`:

```markdown
# Microsoft Graph API Access

## Configuration

- **Tenant ID:** yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
- **Client ID:** xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
- **Token location:** ~/ms365-token.json
- **Refresh script:** ~/refresh-token.sh

## Available APIs

This project has access to Microsoft Graph API with the following permissions:
- User.Read - Read user profile
- Mail.ReadWrite - Read/write emails
- Mail.Send - Send emails
- Calendars.ReadWrite - Read/write calendar events
- Mail.ReadWrite.Shared - Access shared mailboxes

## Usage in Claude Code

```bash
# Get access token
TOKEN=$(jq -r .access_token ~/ms365-token.json)

# Example: List emails
curl -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/me/messages?\$top=10"
```

## Shared Mailboxes

Available shared mailboxes (if delegated):
- support@company.com - Support inbox
- info@company.com - General inquiries
```

---

## Troubleshooting

### Problem: "Insufficient privileges to complete the operation"

**Przyczyna:** Brakujące uprawnienie lub brak admin consent

**Rozwiązanie:**
1. Sprawdź czy uprawnienie jest dodane w Azure Portal → API permissions
2. Sprawdź czy ma status "Granted" (zielony checkmark)
3. Jeśli nie - poproś administratora o "Grant admin consent"

### Problem: "Invalid token" lub 401 Unauthorized

**Przyczyna:** Token wygasł (ważny ~1h)

**Rozwiązanie:**
```bash
# Odśwież token
./refresh-token.sh

# Sprawdź ważność
jq -r .expires_in ms365-token.json
```

### Problem: "The specified object was not found in the store"

**Przyczyna:** Próba dostępu do mailboxa, który nie jest udostępniony

**Rozwiązanie:**
- Dla cudzych mailboxów: musisz mieć delegację lub być członkiem shared mailboxa
- Nie możesz po prostu czytać cudzych maili mając `Mail.ReadWrite.Shared`
- Alternatywnie: użyj `Mail.Read` jako **Application Permission** (wymaga admin consent, daje dostęp do WSZYSTKICH)

### Problem: Access token nie zawiera nowych uprawnień

**Przyczyna:** Token został wygenerowany przed dodaniem uprawnień

**Rozwiązanie:**
```bash
# Wymuś pełną re-autoryzację (wymaga logowania)
# Usuń refresh_token i wygeneruj nowy authorization code
rm ms365-token.json
# Powtórz proces OAuth od początku
```

---

## Przydatne linki

- **Microsoft Graph Explorer:** https://developer.microsoft.com/en-us/graph/graph-explorer
- **Graph API Reference:** https://learn.microsoft.com/en-us/graph/api/overview
- **Permissions Reference:** https://learn.microsoft.com/en-us/graph/permissions-reference
- **Azure Portal:** https://portal.azure.com

---

## Uwagi bezpieczeństwa

1. **Nigdy nie commituj tokenów do git**
   - Dodaj `ms365-token.json`, `.env` do `.gitignore`

2. **Ogranicz uprawnienia do minimum**
   - Używaj Delegated zamiast Application permissions gdy możliwe
   - Nie dawaj `*.All` jeśli nie potrzebujesz dostępu do wszystkich użytkowników

3. **Rotacja sekretów**
   - Client Secret co 12-24 miesiące
   - Ustaw przypomnienia w kalendarzu

4. **Monitoruj dostęp**
   - Azure AD → Sign-in logs
   - Sprawdzaj podejrzane aktywności

---

**Autor:** Marek Bodynek
**Kontakt:** marek.bodynek@kea.si
**Wersja dokumentu:** 1.0 (2026-02-01)
