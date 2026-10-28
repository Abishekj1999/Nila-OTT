# Nila's OTT (Flutter)

Video on demand app for Android and iOS, built on the existing Laravel `/api/v1` API.

## Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=API_BASE_URL=https://your-domain.com/api/v1
```

If you don't pass `API_BASE_URL`, debug builds use the local server: `http://127.0.0.1:8000/api/v1`, or `http://10.0.2.2:8000/api/v1` on the Android emulator. Release builds must pass it.

## Structure

```
lib/core       config, Dio client + error mapping, token storage, theme, router
lib/shared     typed models (json_serializable) and reusable widgets
lib/features   auth, home, catalog, title_details, viewer, playback, premium, shell
```

Libraries: Riverpod for state, GoRouter for navigation, Dio for HTTP, flutter_secure_storage for the Sanctum token, cached_network_image for images, and video_player for HLS and MP4 playback (custom controls in `player_controls.dart`, wakelock_plus keeps the screen on).

UI: dark "cinema" theme. Tokens and type scale live in `lib/core/theme/app_theme.dart`; shared components (buttons, chips, cards, large-title app bars, bottom sheets) are in `lib/shared/widgets`.

## API coverage

All 21 mobile endpoints are wired up. The website's session AJAX routes and the BunnyCDN webhook are deliberately not called.

## Shown as "Coming soon" (needs backend support)

| Feature | Missing |
|---|---|
| Premium plans and checkout, Restore purchases | Plans, purchase and receipt-verification endpoints. Plan cards are display-only design data in `premium_screen.dart`. |
| Mobile number, Google and Facebook login | OTP and social-auth endpoints |
| Forgot password | Password-reset endpoint |
| Search | Search endpoint |
| My List, Downloads, Share, Edit profile, Settings | No endpoints |

## Questions for the backend team

- **Guest playback:** `/playback` requires a token, so the app sends guests to Login before playing anything.
- **Subtitles, audio tracks and DRM** are not in the playback response, so the app doesn't support them yet.
- **Artwork fields:** `poster_url` and `thumbnail_url` don't have a fixed shape. Seeded titles use a portrait poster and a landscape thumbnail, but titles added through the admin are the other way round. The app works around this by checking each image's real size (`ArtworkImage` in `app_image.dart`), but the API should define which field is portrait and which is landscape.
- **More Like This:** there's no recommendations endpoint, so the app builds the rail from the title's genre pages (and its language page when that returns few results), ranked by shared genres, type, language and cast. See `more_like_this.dart`. A server-side `/movies/{slug}/related` endpoint would give better results and save up to four requests per details page.
- **Continue Watching artwork:** items only carry one `thumbnail_url`, so a portrait image gets cropped on the landscape card. A landscape image field there would fix it.

## Dev notes

- **Image URLs:** the local backend returns image URLs as `http://localhost/storage/...`, without the port. Set `APP_URL=http://127.0.0.1:8000` in the Laravel `.env`. Until then, debug builds rewrite localhost media URLs to the API's origin. See `AppConfig.mediaUrl`.
- **Auth rate limit:** auth endpoints allow 5 requests per minute. Repeated logins during testing will return a 429 "Too many attempts" message.
- **Local test account:** credentials are in `.dev-test-account`, which is gitignored.
