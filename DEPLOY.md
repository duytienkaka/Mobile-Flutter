# Deploy Internet (Backend + Landing + APK)

This project can run as a real internet app by deploying the ASP.NET backend (`backend/`) with static files from `wwwroot/`.

## 1) What is already prepared

- Landing page is served from `backend/wwwroot/index.html`.
- APK is downloadable from `backend/wwwroot/downloads/mobile-flutter.apk`.
- APK MIME type is configured in the backend for direct download.
- Backend supports dynamic `PORT` (works on cloud hosts).
- Production CORS supports explicit origins via config.

## 2) Required environment variables

Set these on your host:

- `Jwt__Key`
- `Jwt__Issuer`
- `Jwt__Audience`
- `FIREBASE_CREDENTIALS_JSON` (or `FIREBASE_CREDENTIALS_PATH` / `GOOGLE_APPLICATION_CREDENTIALS`)
- `Gemini__ApiKey` (if AI features are used)
- `Smtp__Host`
- `Smtp__Port`
- `Smtp__Username`
- `Smtp__Password`
- `Smtp__FromEmail`
- `Smtp__FromName`

If hosting with Docker, mount Firebase JSON and set:

- `FIREBASE_CREDENTIALS_PATH=/run/secrets/firebase-service-account.json`

## 3) Quick deploy with Docker (VPS/Linux)

Run from repository root:

```bash
docker build -f backend/Dockerfile -t mobile-flutter-backend .

docker run -d \
  --name mobile-flutter-backend \
  -p 8080:8080 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e PORT=8080 \
  -e ConnectionStrings__DefaultConnection='Host=...;Port=5432;Database=...;Username=...;Password=...' \
  -e Jwt__Key='replace-with-long-secret' \
  -e Jwt__Issuer='FridgeAssistant' \
  -e Jwt__Audience='FridgeAssistantUsers' \
  -e FIREBASE_CREDENTIALS_PATH='/run/secrets/firebase-service-account.json' \
  -v /opt/mobile-flutter/firebase-service-account.json:/run/secrets/firebase-service-account.json:ro \
  mobile-flutter-backend
```

Then put Nginx/Cloudflare in front with HTTPS and route your domain to port `8080`.

## 3.1 Deploy backend on Render

This repo already has `render.yaml` at project root for Render Blueprint deploy.

Steps:

1. Push latest code to GitHub.
2. In Render: `New +` -> `Blueprint` -> select this repository.
3. Render reads `render.yaml` and creates web service `mobile-flutter-backend`.
4. Render creates PostgreSQL `mobile-flutter-db` from `render.yaml` and injects
  `ConnectionStrings__DefaultConnection` automatically into backend.
5. Open service settings -> Environment -> fill secret values:
  - `Jwt__Key`
  - `FIREBASE_CREDENTIALS_JSON` (paste full Firebase service-account JSON as one line)
  - `Gemini__ApiKey` (if needed)
6. Deploy service and wait until status is `Live`.

Database note:

- Backend runs `db.Database.Migrate()` on startup, so Render PostgreSQL is initialized automatically.

Default public URL will look like:

`https://mobile-flutter-backend.onrender.com`

Test quickly:

- Landing page: `https://mobile-flutter-backend.onrender.com/`
- APK direct: `https://mobile-flutter-backend.onrender.com/downloads/mobile-flutter.apk`

## 4) Quick deploy without Docker (Windows/Linux)

From `backend/`:

```bash
dotnet publish -c Release -o publish
```

Run:

```bash
ASPNETCORE_ENVIRONMENT=Production
PORT=8080
ConnectionStrings__DefaultConnection=...
Jwt__Key=...
Jwt__Issuer=FridgeAssistant
Jwt__Audience=FridgeAssistantUsers
FIREBASE_CREDENTIALS_PATH=/absolute/path/firebase-service-account.json

dotnet backend.dll
```

(Use PowerShell `$env:VAR='value'` syntax on Windows.)

## 5) Frontend app API endpoint

Your APK must point to internet backend URL before build.

Build APK with production API URL via dart-define:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://mobile-flutter-backend.onrender.com
```

Copy generated APK to backend landing:

- Source: `frontend/build/app/outputs/flutter-apk/app-release.apk`
- Target: `backend/wwwroot/downloads/mobile-flutter.apk`

## 6) Final checks after deploy

- Landing page: `https://your-domain/`
- APK download: `https://your-domain/downloads/mobile-flutter.apk`
- API health check: call one auth endpoint with Postman
- Push test: login from installed APK and verify FCM token sync

