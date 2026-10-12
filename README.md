# yourname

A Flutter party game for web and mobile, backed by Serverpod 3.4.13, PostgreSQL, and personalized WebSocket streams.

For production releases, see [Deploy to production](#deploy-to-production). The
backend runs on Cloud Run, PostgreSQL runs on Neon, and Flutter web is published
to Firebase Hosting.

## How to play

1. The host creates a room, chooses question categories and a question count (1–30; default: 10), and shares its six-character code.
2. Friends join with unique display names. A room supports 4–20 players (including the host); only the host can start.
3. The server privately deals each player exactly one other player's name. Nobody receives their own name, and each name is assigned once.
4. Everyone answers the same four-choice question as their assigned person. Answers lock on submission; the game advances when everyone has answered.
5. After the last question, each player taps friends’ names to browse their answers, then guesses who had their name. Assigned identities remain hidden until the reveal.
6. When all guesses are in, everyone sees the assignments and results. A correct guess earns one point. The host can return to the lobby and play another round.

Any player can quit from the lobby, questions, guessing, or results screen after confirming a dialog. A non-host quitting during an unfinished round ends it for everyone, clears that round's answers and guesses, and returns the remaining players to the lobby. If the host confirms leaving, the room is deleted and every player returns home; its code and saved seats can no longer be used. A new round requires at least four players; replacement players can join the lobby. Completed account history is preserved. Closing a tab or temporarily disconnecting keeps the seat available for reconnection.

The host can also cancel a stalled round and return everyone to the lobby, where absent players can be removed. Rooms expire 24 hours after creation. Seats and progress survive a refresh or server restart; confirmed missing/expired seats are cleared automatically.

Web URLs distinguish home, `/profile`, and `/room/CODE/lobby`, `/questions`, `/guessing`, or `/reveal` (under the room path). The preview uses Flutter's hash URLs, for example `/app/#/room/ABC234/questions`. Room links prefill the join code for a new player; the URL never grants access to another player's seat. Browser Back asks for confirmation before leaving a room.

## Optional accounts and avatars

Everyone can host or join as a guest and choose from ten built-in animal avatars.
Guests keep their seat on the current device; account creation is never required.
The optional **Sign in** entry supports Firebase email/password (with email
verification and password reset) and Google on the web.

Signed-in players can save their name, choose an avatar or upload a JPEG/PNG,
resume their active seats from **Profile & games → My games**, and revisit their
latest 100 completed rounds. Signing in during a game claims the current guest
seat. Resuming on another device rotates its seat token. Signing out clears the
local seat, while its server-side account record remains resumable. Rooms still
expire after 24 hours; completed-round snapshots survive room expiry and resets.

Profiles, saved seats, and completed rounds are PostgreSQL/Serverpod models.
Firebase supplies identity only; its ID token is verified by Serverpod's Firebase
provider before issuing a Serverpod session. Account endpoints require a verified
session, and never accept a client-supplied account ID. Photos are limited to 1 MB
and 2048×2048 input, then cropped/re-encoded to a 96×96 JPEG with metadata removed.
Avatar changes are applied in the lobby so appearances stay stable during a round.

The Firebase web app is registered in `yourname-lky`; its public configuration is
in `yourname_flutter/lib/firebase_options.dart`. Enable Email/Password and Google
in Firebase Authentication and authorize each deployed web domain (and `localhost`
for development). Set `FIREBASE_PROJECT_ID` on the server to use a different project.
Native Firebase apps have not been registered: replace the template app/bundle IDs
with your intended identifiers and run FlutterFire configuration before native
account sign-in. Guest play remains available if Firebase cannot initialize.

Apply migration `20261010100646367` when deploying the server. Local account tests
use a separate database via the standard `SERVERPOD_DATABASE_*` environment
variables and `dart test test/integration/account_game_test.dart`.

## Code layout

- `yourname_flutter/lib/game`: responsive screens and reconnecting client controller.
- `yourname_server/lib/src/game`: rules, guest-seat API, private state projections, database models, and question seed.
- `yourname_client`: generated client, including the WebSocket `game.watch` method.
- `.tools/serverpod_cli`: pinned generator; invoke it through `tool/serverpod.ps1`.

The question bank has **40 questions in 4 categories**: Everyday, Food & drink, Personality, and Would you rather. Questions live in the `party_question` database table. Stable seed slugs prevent duplicates, and existing rows are preserved so prompts/options can be edited or disabled. Each valid question has exactly four choices. The server randomly selects non-repeating questions from the chosen categories.

Room state is persisted in the server-only `game_room` table. PostgreSQL row locks serialize concurrent joins and submissions. The API authenticates seats with a random 256-bit bearer secret and stores only its SHA-256 digest. It sends each player a filtered view, never raw assignments or other players' credentials. Native [Serverpod streaming methods](https://docs.serverpod.dev/3.4.0/concepts/streams) deliver updates over WebSockets; room events provide immediate delivery with a five-second reconciliation tick for expiry and cross-process recovery.

## Local preview on this computer

The verified preview uses an isolated PostgreSQL cluster in `.local/postgres`, bound to `127.0.0.1:18090`, with database `yourname_smoke`. It does not use the existing PostgreSQL service on port 5432. This local-only cluster uses trust authentication and must stay bound to loopback.

To restart the preview server from the project root:

```powershell
.\tool\run-preview.ps1
```

Open `http://localhost:18082/app/` for the built web app. API/WebSocket traffic uses port 18080. To develop Flutter against that server:

```powershell
cd yourname_flutter
flutter run -d chrome
```

Each browser profile/device has one saved seat. Use separate browser profiles or devices to play as different people.

### Debugging in Zen or another browser

Run these commands in two terminals you own, and keep both open. If the backend
is already running, keep that session and run only the frontend command:

```powershell
# Terminal 1: backend
.\tool\run-preview.ps1

# Terminal 2: Flutter development server
.\tool\run-frontend.ps1
```

The backend launcher checks ports 18080–18082 before starting. If they are
occupied, it stops with a message instead of launching a duplicate backend.
To restart the backend, stop its existing session first.

Open `http://localhost:18083/` in Zen. This uses Flutter's `web-server` device,
so it does not depend on a Chrome debug window. The terminal displays the
available reload/restart commands; press `q` when you want to stop it. Zen's
developer tools can inspect the page, console, and network. For Flutter's
integrated Chrome debugging, run `.\tool\run-frontend.ps1 -Device chrome` instead.

Copying a URL from a Flutter Chrome debug session into Zen does not create a
separate development server: Zen still depends on the original Flutter process.
Use your own terminal rather than a temporary agent command session for long
interactive debugging. Closing either required terminal stops its service.

## Standard Docker setup

With Docker Desktop running, from the project root:

```powershell
cd yourname_server
docker compose up -d postgres
dart run bin/main.dart --apply-migrations
```

In another terminal:

```powershell
cd yourname_flutter
flutter run -d chrome
```

This uses the standard API port 8080 and database port 8090. The API seeds the question bank idempotently on the first category request. Redis is optional and disabled in the supplied development config.

## Mobile

For an Android emulator with the isolated preview server:

```powershell
cd yourname_flutter
flutter run -d <device-id> --dart-define=SERVER_URL=http://10.0.2.2:18080/
```

For a physical device, use the server computer's LAN address instead of localhost, and ensure the device can reach it. Android debug builds permit local HTTP; release builds should use an HTTPS server, which also provides WSS. iOS requires a Mac/Xcode toolchain and an appropriate HTTPS endpoint or a development-only transport exception. Physical-device gameplay has not been verified.

## Generation and migrations

From the project root:

```powershell
.\tool\serverpod.ps1 generate
.\tool\serverpod.ps1 create-migration
```

The project uses Flutter 3.44.0 / Dart 3.12.0 with Serverpod 3.4.13. The pinned CLI avoids changing the global Serverpod installation. Keep generated client/server protocol files together with model and endpoint changes.

## Tests

```powershell
flutter analyze
cd yourname_server
dart test test/unit
cd ../yourname_flutter
flutter test
dart run tool/multiplayer_smoke.dart http://127.0.0.1:18080/
```

The multiplayer smoke test creates a local test room and runs four real clients through ten questions, concurrent answers, WebSocket updates, reconnection, guesses, replay, privacy checks, and invalid-action rejection. Run it only against a disposable/local database. Unit tests include 500 randomized assignment checks. Widget tests cover all five screens at 320, 375, 768, 844 (landscape), 1024, 1440, and 1920 pixels with normal and doubled text, plus keyboard visibility, selection across resizing, and motion preferences.

## Responsive interface

Phones use compact spacing, stacked room controls and full-width answers. On tablets, the main content is centered with a 720-pixel maximum width. The player list expands on demand below the game on both sizes. With at least 960 pixels of available content width, the home page uses two columns and the game shows a 300-pixel player sidebar. Overall content stops growing at 1160 pixels. Answer choices use two columns when their own available width reaches 560 pixels. Enlarged text switches back to single-column layouts; answer tiles grow naturally for longer text. Forms scroll above the keyboard and dragging dismisses it.

## Rebuild the hosted web preview

The Flutter UI uses `animate_do` for short, one-shot entrances: a 12-pixel fade upward for the home screen and game phases/questions, and a quiet fade for the reveal. Stable room updates preserve animation state. System reduced-motion settings show content immediately without these effects. Styling and motion are shared by web and mobile.

From the project root:

```powershell
cd yourname_flutter
flutter build web --base-href /app/ --dart-define=SERVER_URL=http://localhost:18080/
cd ..
Copy-Item -Path yourname_flutter/build/web/* -Destination yourname_server/web/app -Recurse -Force
```

The web loader uses a build hash in entry-point URLs so a refresh loads the current app even when older JavaScript remains in the browser cache.

## Current scope

This is a playable MVP with guest rooms. It has no question-management UI, automatic host takeover during an active round, public-service rate limiting, or expired-room cleanup job. A host who disconnects can resume using their saved seat. Question categories are stored on each question; edit questions through the database or extend the seed with new stable slugs. Existing seed rows are intentionally not overwritten.

Local passwords are in `yourname_server/config/passwords.yaml`; keep credentials and `.local` data out of version control. Optional Firebase account sign-in needs the additional configuration described below.


## Verification completed

- Clean Flutter static analysis.
- 12 server rule tests, including 500 randomized name assignments.
- 76 widget tests: 70 screen/viewport/text-size combinations, keyboard reachability, selection across resizing, animation replay, reduced motion, and the three/four-player start boundary.
- Five real clients completed a ten-question game over the local Serverpod API and WebSockets, including concurrent submissions and reconnect.
- Chrome room creation and saved-seat recovery after refresh verified.
- Release web build and Android debug APK build passed. The APK uses the Android emulator address `http://10.0.2.2:18080/`.
- iOS compilation and physical-device gameplay have not been tested.

The Android build disables Kotlin incremental compilation to avoid a cross-drive Windows cache failure. The scaffold's optional authentication plugins still emit a future Kotlin plugin compatibility warning, but the current build succeeds.

## Deploy to production

These commands target the existing `whosme-511315` Google Cloud/Firebase project
and `snowy-meadow-62290628` Neon project. They assume the Cloud Run service
account `whosme-backend`, Artifact Registry repository `whosme`, Firebase Hosting
site, and required Google Cloud APIs already exist. Run them in PowerShell from
the repository root. Install Flutter/Dart, the `gcloud`, `firebase`, and `neon`
CLIs, then sign in to each CLI with access to those projects.

1. Run `dart pub get` from the repository root. Copy
   `yourname_flutter/lib/env.example.dart` to the gitignored
   `yourname_flutter/lib/env.dart` if it does not already exist.
2. Select the production Neon branch with the Neon CLI and run `neon env pull`
   from the repository root. The resulting gitignored `.env.local` must contain
   both `DATABASE_URL` (pooled, for Cloud Run) and `DATABASE_URL_UNPOOLED`
   (direct, for migrations). Keep this file and all secret values out of Git.
3. For an initial deployment, run `.\tool\configure-cloud-run.ps1` to
   prepare `.local/cloud-run.production.json`, create any missing Secret Manager
   secrets, and grant the Cloud Run service account access. For later deployments,
   rerun it when the Neon connection settings change. Existing secret values
   are preserved; rotate them separately if the underlying credentials change.
4. Apply pending schema migrations before deploying a backend that uses them:
   `.\tool\migrate-neon.ps1 -Branch production`. For schema changes, first
   run the same script against a temporary Neon validation branch with its
   branch name passed to `-Branch`.
5. Run `.\tool\deploy-backend.ps1`. It builds the backend with Cloud Build,
   pushes the image to Artifact Registry, and deploys `whosme-api` to Cloud Run.
   Run the guest-flow smoke test below against the deployed API.
6. Run `.\tool\deploy-web.ps1` to build Flutter for the production API and
   publish only Firebase Hosting. Use `-BuildOnly` to inspect the web build
   without publishing. Then open `https://whosme-511315.web.app` and check a
   guest game in the browser.

The migration and smoke-test commands touch the selected database. Confirm the
Neon branch and API URL before running them. The deployment scripts do not copy
local room data into production.

### Local and production environments

Copy `yourname_flutter/lib/env.example.dart` to `yourname_flutter/lib/env.dart`
when setting up a new checkout. `env.dart` is ignored by Git and is the single
place to select `AppEnvironment.local` or `AppEnvironment.production`.
Fully restart/rebuild Flutter after changing it; hot reload does not recreate
the API client. `SERVER_URL` Dart defines no longer select the backend.
The selector currently defaults to local.

- Local API: `http://localhost:18080/`, started by `tool/run-preview.ps1`.
- Production API: `https://whosme-api-759833941649.us-east4.run.app/`.
- Cloud Run: `whosme-api`, Google project `whosme-511315`, region `us-east4`.
- Production database: Neon project `snowy-meadow-62290628`, branch `production`.

On a physical device, set `localServerUrl` to this computer's LAN address;
`localhost` refers to the device itself. Keep database passwords and signing
keys out of Flutter: the app contains only backend URLs. Local and production
seats/auth sessions use distinct storage keys derived from their backend URL.
Firebase identity continues to use the existing `yourname-lky` project in both
environments; database records and Serverpod sessions are separate.

### Backend deployment

Cloud Build uploads only the backend source permitted by `.gcloudignore`.
The runtime image excludes local passwords and Firebase service-account files.
Cloud Run uses a dedicated `whosme-backend` service account with access only to
its five Secret Manager secrets. The database uses TLS and the pooled Neon
connection; migrations use the direct connection. Local database records are
not copied into production. The normal idempotent question seed runs when the
question categories are first requested.

With the prerequisites above in place:

```powershell
# Initial setup, or refresh database settings (preserves existing secrets):
.\tool\configure-cloud-run.ps1

# For schema changes, first validate on a temporary Neon branch:
$validationBranch = 'replace-with-your-validation-branch'
.\tool\migrate-neon.ps1 -Branch $validationBranch
.\tool\migrate-neon.ps1 -Branch production

# Build and deploy backend:
.\tool\deploy-backend.ps1

# Validate a full guest game over HTTPS/WebSocket; removes its temporary room:
dart --packages=.dart_tool/package_config.json tool/smoke-backend.dart https://whosme-api-759833941649.us-east4.run.app/
```

The deployment uses 0 minimum and 3 maximum instances, 512 MiB memory, a
5-connection database pool per instance, and a 60-minute request timeout.
The existing client reconnects WebSockets; persisted room state and the
five-second reconciliation tick support connections across instances.
Only the API port is public on Cloud Run; it does not expose Serverpod Insights.
Flutter web is hosted separately on Firebase Hosting. Secret bindings pin version 1; rotate
secrets deliberately and update the binding in `tool/deploy-backend.ps1`.

### Flutter web deployment

Production website: https://whosme-511315.web.app

```powershell
.\tool\deploy-web.ps1
```

The script temporarily selects production in the gitignored `lib/env.dart`,
builds Flutter web, then restores the original selection even if the build
fails. It checks that the compiled bundle points to Cloud Run before publishing
only Hosting to Firebase project `whosme-511315`. Use `-BuildOnly` to build
without publishing. Hosting rewrites app routes to `index.html` and revalidates
assets on reload. Backend and database deployment remain separate commands.

The existing Firebase Auth project remains `yourname-lky`. At web deployment,
its Auth Admin API returned `CONFIGURATION_NOT_FOUND`; email/Google account
sign-in still requires initializing Firebase Authentication, enabling the
providers, and authorizing `whosme-511315.web.app` and
`whosme-511315.firebaseapp.com` in that project. Guest play uses Cloud Run and
Neon and does not require Firebase Authentication.
