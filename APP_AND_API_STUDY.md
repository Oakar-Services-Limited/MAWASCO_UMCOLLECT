# MAWASCO Mobile App & API – Study Summary

A concise overview of **MAWASCO_MOBILE** (Flutter) and **MAWASCO_API** (Node/Express) and how they work together.

---

## 1. MAWASCO_MOBILE (Flutter app – `um_collect`)

### Purpose
Field data-collection app for **Mathira Water and Sanitation Company (MAWASCO)**. Used by:
- **Staff**: asset mapping, meter readings, NRW (Non-Revenue Water), incidents, routing, customer supply feedback.
- **Public**: report incidents, supply feedback, wallet (when applicable).

### Structure
| Area | Contents |
|------|----------|
| **lib/pages** | Auth (landing, login, stafflogin, publiclogin, register), home, Assets, NRW, incidents, meter readings, mapping/routing, FormsListPage, FormFillPage, Settings, Wallet, etc. |
| **lib/pages/Forms** | ~28 asset forms: WaterPipes, Tanks, Kiosks, Valves, Washouts, Boreholes, MasterMeters, CustomerMeters, SewerLines, ManHoles, GritChamber, PumpingStations, SewerTreatment, SewerMainTrunk, NewWaterConn, NewSanConn, NRWMetersReading, Interventions, LineProjects, PointProjects, Offtakers, Appurtenances, ConnectionChambers, CustomerChambers, ConsumerLine, CustomerLines, etc. |
| **lib/components** | Utils (API URL, JWT parse, DMA list, etc.), StaffDrawer, Map, inputs (MyTextInput, MySelectInput, MySearchableSelectInput), SubmitButton, dialogs, incident/NRW items. |
| **lib/services** | **RationingScheduleService** (loads `assets/config/rationing_schedule.json` for Customer Supply Feedback), **UtilityCacheService** (caches schemes, subzones, wards, constituencies in secure storage for offline form dropdowns). |
| **lib/controllers** | feedback_controller (customer feedback API). |
| **lib/models** | rationing_schedule_entry, customer_feedback, customer, Map, grid_icons, LineMap. |
| **lib/utils** | form_logic. |
| **lib/theme** | app_theme. |

### API configuration
- **Single source**: `lib/components/Utils.dart`.
- **`getUrl()`** returns the API base URL (e.g. `http://192.168.1.136:3003/api/` or production `https://api-utilitymanager.mawasco.co.ke/api/`).
- All HTTP calls use `getUrl()` (e.g. `${getUrl()}admin/login`, `${getUrl()}wt/master-meters`).
- No env-based config; switch URL in code or extend Utils for env.

### Authentication
- **Staff**: `stafflogin.dart` → POST `${getUrl()}admin/login` with `email`, `password`, `type: 'Mobile'`, `appVersion`. On success, JWT stored in **FlutterSecureStorage**: `mwstaffjwt`, `isstaff: 'true'`. Then FCM token registration and navigate to Home.
- **Public**: JWT key `mwjwt` (e.g. reportIncident, public flows).
- **Startup**: `main.dart` → read `mwstaffjwt`, validate with `parseJwt()` from Utils. Missing/invalid → Login; valid → Home (optional version check).
- **API calls**: Each screen that needs auth reads token from storage and sends `Authorization: Bearer <token>`. No single shared HTTP client that injects the header globally.

### Key dependencies (pubspec.yaml)
- **Auth/storage**: flutter_secure_storage, shared_preferences.
- **HTTP**: http.
- **Maps/location**: google_maps_flutter, geolocator, location, flutter_polyline_points.
- **Media**: image_picker, permission_handler, url_launcher.
- **Notifications**: firebase_core, firebase_messaging, flutter_local_notifications, flutter_background_service.
- **UI**: loading_animation_widget, webview_flutter, flutter_html, google_fonts, intl, provider.

**Note:** The current codebase does **not** include `sqflite` or `connectivity_plus`. Form submissions are done over HTTP when the user saves; “offline” is limited to **UtilityCacheService** (cached lookups) and **RationingScheduleService** (local JSON).

### Main user flows
1. **Staff**: Open app → location permission → if no/invalid staff token → Login → Staff Login → JWT stored → Home. From Home: asset forms, Master/NRW meter readings, incidents (assigned/pending/complete), Assets, Routing, Navigate to asset/NRW, Customer supply feedback, Settings, Wallet. Forms load definitions from API and submit with `Authorization: Bearer <token>`.
2. **Public**: Login → Public Login or Register → report incidents, view incidences, Customer supply feedback (zone/area/route from rationing schedule).

---

## 2. MAWASCO_API (Node/Express backend)

### Purpose
Backend for MAWASCO utility (water & sewer) management: auth, water/sewer assets, billing/meter readings, O&M, NRW, forms/field data, support, messaging, dashboard stats, GeoJSON, FCM, customer feedback.

### Structure
| Area | Contents |
|------|----------|
| **Entry** | `src/server.js` (start), `src/app.js` (Express app, CORS, route mounting). |
| **src/config** | Database (Sequelize/PostgreSQL), env. |
| **src/controllers** | admin_controller (auth, asset search), wt_* (water assets), sr_* (sewer), pj_* (projects), bl_* (billing), om_* (O&M), nrw_* (NRW), meter_reading, master_meter_reading, form_controller, field_data, customer_feedback, dashboard_stats, support, messages, fcm_tokens. |
| **src/routes** | One (or more) route file per domain (admin_routes, wt_*_routes, sr_*_routes, etc.). |
| **src/middleware** | auth_middleware (JWT: authenticateAdmin, authenticateUser), error_handler, audit_context. |
| **src/models** | Sequelize models + associations.js (Admin, wt_*, sr_*, pj_*, bl_*, om_*, nrw_*, meterreading, master_meter_reading, form_definition, audit_trail, support, messages, fcm_tokens, customer_feedback). |
| **src/services** | audit_service, auth_mail_service, notification_service. |
| **src/schedulers** | cron_jobs, cron_functions (e.g. billing fetch, notifications). |

### URL handling
- Client (mobile) calls e.g. `https://host/api/admin/login`.
- In `app.js`, middleware strips `/api`, so server sees `/admin/login`. All route mounts are defined **without** the `/api` prefix.

### Main API surface (server path after stripping `/api`)
| Base path | Purpose |
|-----------|---------|
| `/admin` | Login, register, mydetails, forgot/reset/change password, admin CRUD, logout, search (e.g. `/admin/:searchItem/:objectId`), asset search under `/wt/assetsearch`. |
| `/wt/*` | Water: master-meters, tanks, kiosks, washouts, water-pipes, customer-meters, valves. |
| `/sr/*` | Sewer: sewer-lines, manholes, pumping-station, grit-chamber, sewer-treatment; `/sewer` for network stats. |
| `/pj/points`, `/pj/lines` | Project points/lines. |
| `/bl/*` | Billing: meter-readings, invoices, invoices-issued, customer-billing. |
| `/om/reports`, `/om/categories`, `/om/assigned-reports` | O&M. |
| `/nrw*`, `/nrw_dmareadings`, `/nrw_interventions` | NRW leakages, analysis, DMA readings, interventions. |
| `/meter-reading`, `/master-meter-reading` | Meter readings. |
| `/stats` | Dashboard stats. |
| `/forms`, `/field-data` | Form definitions and submissions. |
| `/customer-feedback` | Customer feedback. |
| `/geojson/:table` | GeoJSON by table. |
| `/fcm-tokens` | FCM registration. |
| `/support`, `/messages` | Support and messages. |

### Authentication and authorization
- **JWT**: Issued in admin_controller (`generateToken(admin)`), payload `{ id }`, signed with `process.env.JWT_SECRET`, expiry 1h. Used for both admin and user flows.
- **authenticateAdmin**: Reads token from cookie `authToken` or `Authorization: Bearer <token>`, verifies JWT, loads Admin by `decoded.id`, sets `req.admin`. No role check in middleware.
- **authenticateUser**: Verifies JWT and requires `decoded.role === "User"`; sets `req.user` (less used in described routes).
- **Admin model**: Roles (e.g. Super Admin, Admin, Management, Commercial, NRW/O&M, Regular User), **accessLevel**: Full, Admin Only, **Mobile Only**. Login enforces:
  - `type === "Mobile"` → accessLevel must be **Mobile Only** or **Full**.
  - `type === "Web"` → accessLevel must be **Admin Only** or **Full**.

### Database
- **Sequelize** + **PostgreSQL**. Config: `PGDATABASE`, `PGUSER`, `PGPASSWORD`, `PGHOST`, `PGPORT`.
- Tables align with models: Admin; wt_* (valves, master_meters, tanks, etc.); sr_* (sewerlines, manholes, pumping_station, etc.); pj_*; bl_*; om_*; nrw_*; meterreading; master_meter_reading; form_definition; audit_trail; support; messages; fcm_tokens; customer_feedback. Some geometry/GeoJSON via raw SQL (e.g. PostGIS-style).

---

## 3. How the app and API work together

1. **Base URL**: Mobile uses `Utils.getUrl()` (e.g. `.../api/`). All requests go to `baseUrl + path` (e.g. `getUrl() + 'admin/login'` → `.../api/admin/login`). API strips `/api` and routes on the rest.
2. **Staff login**: App POSTs to `/api/admin/login` with `email`, `password`, `type: 'Mobile'`. API validates, checks accessLevel for Mobile, returns JWT. App stores `mwstaffjwt` and uses it as `Authorization: Bearer <token>` on subsequent requests.
3. **Asset forms**: Forms submit to the corresponding API path (e.g. wt/master-meters, sr/manholes, nrw_dmareadings). Many routes do not explicitly use `authenticateAdmin` in the codebase; auth may be enforced at gateway or intended to be added.
4. **Lists and reads**: App calls same API for lists, search, and details (e.g. master meters, assets, incidents, NRW). Dashboard stats from `/api/stats`, GeoJSON from `/api/geojson/:table`.
5. **Lookups for forms**: UtilityCacheService caches schemes, subzones, wards, constituencies from the API (e.g. 7-day cache) so dropdowns work from cache when offline.
6. **Notifications**: App registers FCM token with API (`/api/fcm-tokens`); API uses it for push (e.g. incident assignments).

---

## 4. Quick reference – Mobile → API mapping (examples)

| App action | API path (client uses getUrl() + path) |
|------------|----------------------------------------|
| Staff login | `admin/login` (POST) |
| Master meter list | `wt/master-meters` (GET) |
| Master meter create/update | `wt/master-meters` (POST/PUT) |
| NRW reading search | `nrwreading/search/:value` (GET) |
| NRW DMA readings | `nrw_dmareadings` (POST/PUT) |
| Customer feedback | `customer-feedback` (POST) |
| Forms list / submit | `forms`, `field-data` |
| Dashboard stats | `stats` (GET) |
| GeoJSON for maps | `geojson/:table` (GET) |

---

This document reflects the current state of both repositories. If you add offline queue/sync (e.g. sqflite, connectivity_plus, database_service, sync_service, offline_submit_service), update this study and the migration/status docs accordingly.
