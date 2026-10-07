# Smart Energy Tanzania

A Flutter client and Laravel API for managing user accounts, meter records,
balances, and transfer records. Account data is stored in MySQL database
`smart`; the app has no sample-data fallback when the API cannot be reached.

## What works

- Register and sign in using Laravel Sanctum personal access tokens.
- Add meter records with a name, number, type, and starting balance.
- Record balance movements between meters owned by the signed-in account.
- Meter balances and transfer history are stored and served by MySQL.
- Create a printable/shareable PDF ticket for a database transfer record.

**Not connected to TANESCO:** meter numbers are not verified against a utility,
and these app-only balance movements do not change physical meter units.
TANESCO verification, live readings, and real utility transfers are a separate
future integration.

## Project structure

```text
backend/
├── app/
│   ├── Http/Controllers/Api/
│   └── Models/
├── database/migrations/
├── routes/api.php
└── tests/Feature/
lib/
├── main.dart
├── models/
│   ├── energy_transfer.dart
│   └── meter.dart
├── screens/
│   ├── dashboard_screen.dart
│   └── session_gate.dart
├── services/
│   ├── energy_api_client.dart
│   ├── session_storage.dart
│   └── transfer_ticket_service.dart
├── theme/
│   └── app_theme.dart
└── widgets/
    ├── app_card.dart
    ├── balance_card.dart
    ├── meter_card.dart
    ├── quick_action.dart
    └── usage_trend_card.dart
```

- `backend/` is a Laravel 12 API. Its `users`, `meters`, and `energy_transfers`
  tables are linked by foreign keys; Sanctum stores API tokens in
  `personal_access_tokens`.
- `models/` contains meter and transfer records.
- `services/` owns authenticated API access, secure token storage, and PDF
  ticket generation.
- `screens/` composes the app pages and handles navigation and interactions.
- `widgets/` contains reusable cards and meter/dashboard components.
- `theme/` contains shared app colors and Material styling.

## Set up the Laravel API

Create the MySQL database once:

```sql
CREATE DATABASE smart CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Then configure and start the API:

```sh
cd backend
copy .env.example .env
composer install
php artisan key:generate
php artisan migrate
php artisan serve --host=0.0.0.0
```

Set `DB_HOST`, `DB_PORT`, `DB_USERNAME`, and `DB_PASSWORD` in `backend/.env` to
match your MySQL installation. Never put database credentials in the Flutter
app. On a deployed server, set `APP_ENV=production` and `APP_DEBUG=false`, use
HTTPS, and keep `.env` private.

The API requires authentication for account and energy data:

| Method | Endpoint | Purpose |
| --- | --- | --- |
| POST | `/api/register` | Create account and API token |
| POST | `/api/login` | Sign in and issue API token |
| POST | `/api/logout` | Revoke current token |
| GET | `/api/user` | Verify token and get profile |
| GET | `/api/dashboard` | Load account meters and transfer history |
| GET / POST | `/api/meters` | List or add an account meter record |
| GET / POST | `/api/transfers` | List or record a balance movement |

`POST /api/transfers` locks both account-owned meter rows and updates both
balances and the transfer record within one database transaction.

## Run the Flutter app

```sh
flutter pub get
flutter run --dart-define=SMART_ENERGY_API_URL=http://10.0.2.2:8000/api
```

The example URL is for an Android emulator accessing a Laravel server on the
development computer. Use `http://127.0.0.1:8000/api` for web/desktop on that
computer, or replace the host with your server's address. For Flutter web,
add its exact origin to `CORS_ALLOWED_ORIGINS` in `backend/.env`.

## Validate both projects

```sh
flutter analyze
flutter test
cd backend
php artisan test
```
