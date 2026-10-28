<div align="center">

<img src="frontendflutter/assets/images/logo.png" alt="PinFood logo" width="110">

# PinFood

**Find restaurants that fit your diet, on a map.**

Final degree project (Software Engineering, University of Málaga). Repository name: `RestEspe`.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat-square&logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python_3.12-3776AB?style=flat-square&logo=python&logoColor=white)
![SQLAlchemy](https://img.shields.io/badge/SQLAlchemy-D71F00?style=flat-square&logo=sqlalchemy&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL_+_PostGIS-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)
[![Backend tests](https://github.com/maarcoos8/RestEspe/actions/workflows/backend-tests.yml/badge.svg)](https://github.com/maarcoos8/RestEspe/actions/workflows/backend-tests.yml)

</div>

---

PinFood is a mobile app for people with specific dietary needs. It shows nearby restaurants on a map and lets you filter them by diet, type of place and rating. Each dish on a menu is tagged with the diets it suits, and every restaurant automatically shows the diets it caters for, based on its menu. Users can leave reviews, upload photos, save favourites and vote on whether a listing is accurate.

## Screenshots

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/map.png" width="220" alt="Map with nearby restaurants"><br><sub>Map search</sub></td>
    <td align="center"><img src="docs/screenshots/filters.png" width="220" alt="Search filters"><br><sub>Filters</sub></td>
    <td align="center"><img src="docs/screenshots/detail.png" width="220" alt="Restaurant detail"><br><sub>Restaurant detail</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/reviews.png" width="220" alt="Reviews"><br><sub>Reviews</sub></td>
    <td align="center"><img src="docs/screenshots/admin.png" width="220" alt="Admin panel"><br><sub>Admin panel</sub></td>
    <td></td>
  </tr>
</table>

## Features

**Search**
- Map of restaurants based on OpenStreetMap, centred on your location or on any address you search for. Verified places stand out with a green border.
- List view sorted by distance, as an alternative to the map.
- Filters by distance, name, type of place, diet (a place must match **all** the selected diets), minimum average rating and verified places only.
- Distance filtering runs in the database with PostGIS.

**Restaurants**
- Detail page with contact details, photo gallery, average rating and the diets the place caters for.
- Menu grouped by sections. Each dish is tagged with one or more diets, and the app shows how many dishes suit each diet.
- Share a restaurant with a link that opens it directly in the app.

**Community**
- Sign in with Google.
- Reviews with a star rating in half-point steps, an optional comment and an optional photo. Managers cannot review their own restaurant.
- Favourites.
- Community validation: users vote up or down on whether a listing is accurate.
- Photos uploaded by users, stored in Cloudinary.

**Roles and administration**
- Four roles: **User**, **Manager** (runs their own restaurants and menus), **Global Admin** and **Superadmin**.
- Verified restaurants: managers and admins can mark a place as verified. Editing the menu of a verified place removes the verification and asks whether to verify it again.
- Admin screens to manage users and their roles, restaurants, diet categories with their colour and types of place.

## Architecture

```mermaid
flowchart LR
    app["Flutter app<br/>(Android / iOS)"]
    google["Google Sign-In"]
    api["FastAPI backend<br/>REST API /api/v1"]
    db[("PostgreSQL<br/>+ PostGIS")]
    cdn["Cloudinary<br/>(images)"]
    osm["OpenStreetMap<br/>tiles + Nominatim"]

    app -- "1. sign in" --> google
    google -- "ID token" --> app
    app -- "2. HTTP + Bearer ID token" --> api
    api -- "verifies token" --> google
    api -- "SQLAlchemy + GeoAlchemy2" --> db
    api -- "uploads" --> cdn
    app -- "map tiles and geocoding" --> osm
```

The app signs in with Google and sends the Google ID token as a Bearer token. A backend middleware verifies that token on every write request (`POST`, `PUT`, `DELETE`). The backend follows a layered structure: `endpoints` → `crud` → `models`, with Pydantic `schemas` for input and output.

## Data model

```mermaid
erDiagram
    ROLES ||--o{ USUARIOS : has
    USUARIOS ||--o{ RESENA : writes
    USUARIOS ||--o{ FOTOGRAFIA : uploads
    USUARIOS }o--o{ ESTABLECIMIENTO : "favourites"
    USUARIOS }o--o{ ESTABLECIMIENTO : "validates (+1 / -1)"
    USUARIOS |o--o{ ESTABLECIMIENTO : manages
    ESTABLECIMIENTO ||--o{ RESENA : receives
    ESTABLECIMIENTO ||--o{ FOTOGRAFIA : has
    ESTABLECIMIENTO ||--o{ ITEM_MENU : offers
    ESTABLECIMIENTO ||--o{ TIPO_ITEM_MENU : "menu sections"
    ESTABLECIMIENTO }o--o{ TIPO_ESTABLECIMIENTO : "is a"
    ESTABLECIMIENTO }o--o{ CATEGORIA_DIETA : "caters for (auto-synced)"
    ITEM_MENU }o--o{ CATEGORIA_DIETA : "suits"
    TIPO_ITEM_MENU |o--o{ ITEM_MENU : groups

    ESTABLECIMIENTO {
        int id_establecimiento PK
        string nombre
        string direccion_texto
        string contacto
        geometry coordenadas "POINT, SRID 4326"
        bool estado_verificado
        int responsable_id FK
    }
    ITEM_MENU {
        int id_item_menu PK
        string nombre_item_menu
        float precio
        int id_establecimiento FK
    }
    CATEGORIA_DIETA {
        int id_categoria PK
        string nombre_dieta
        string color_hex
    }
    RESENA {
        int id_resena PK
        float puntuacion "0-5, half steps"
        string comentario
    }
```

Table and column names are in Spanish, as in the code.

## Technical decisions

**Diet categories kept in sync with SQLAlchemy events.**
A restaurant caters for a diet if, and only if, at least one dish on its menu is tagged with that diet. Instead of asking managers to keep this up to date by hand, listeners in [`app/events/menu_category_sync.py`](backendFastApi/app/events/menu_category_sync.py) react to inserts, updates and deletes on dishes and dish-diet links, and add or remove rows in `establecimiento_categoria`. They use SQLAlchemy Core on the connection of the flush that triggered the event, so the sync runs inside the same transaction and does not trigger new flushes. Before a dish is deleted, its diets are cached so they can be recalculated afterwards.

**Geospatial queries in the database with PostGIS.**
Coordinates are stored as a `Geometry(POINT, 4326)` column with GeoAlchemy2. The nearby search filters with `ST_DistanceSphere(coordenadas, ST_SetSRID(ST_MakePoint(lon, lat), 4326)) <= distance`, so the database does the filtering instead of loading every restaurant into Python. Latitude and longitude are exposed as hybrid properties (`ST_Y` / `ST_X`).

**Diet filter with "match all" semantics.**
When several diets are selected, the query groups by restaurant and keeps only those where `COUNT(DISTINCT id_categoria)` equals the number of selected diets. A restaurant that is only vegan does not show up when you search for vegan and gluten-free.

**Stateless authentication with Google ID tokens.**
The backend does not issue its own sessions. A middleware verifies the Google ID token (signature, expiry and audience) with `google-auth` on every write request. Read endpoints are public.

**Deep links with a web fallback.**
Shared links point to `/deeplink/establecimiento/{id}`, an HTML page that tries to open `pinfood://establecimiento/{id}` and explains what to do if the app is not installed.

**Schema migrations with Alembic.**
Schema changes made after the first version (diet colours, restaurant manager, nullable menu sections, contact field and validation votes) are tracked as Alembic migrations.

## Project structure

```
RestEspe/
├── backendFastApi/
│   ├── app/
│   │   ├── api/v1/endpoints/   # REST endpoints
│   │   ├── core/               # config, roles, Google token verification
│   │   ├── crud/               # data access
│   │   ├── db/                 # engine, session, declarative base
│   │   ├── events/             # SQLAlchemy listeners (diet sync)
│   │   ├── models/             # SQLAlchemy models
│   │   ├── schemas/            # Pydantic schemas
│   │   ├── services/           # Cloudinary
│   │   └── main.py
│   ├── migrations/             # Alembic
│   ├── scripts/init_db.py      # creates tables and roles on a new database
│   ├── tests/                  # pytest
│   └── Dockerfile
├── frontendflutter/
│   └── lib/
│       ├── core/               # constants, theme, deep links, token store
│       ├── data/               # models and API services
│       ├── providers/          # state (provider)
│       ├── screens/
│       └── widgets/
└── docker-compose.yml          # backend + PostgreSQL/PostGIS
```

## Running locally

### Backend with Docker (recommended)

Requirements: Docker and Docker Compose.

```bash
git clone https://github.com/maarcoos8/RestEspe.git
cd RestEspe
cp backendFastApi/.env.example backendFastApi/.env   # fill in Google and Cloudinary
docker compose up --build
```

This starts PostgreSQL with PostGIS and the backend. On first start, `scripts/init_db.py` creates the tables, inserts the four roles and marks the Alembic migrations as applied. `DATABASE_URL` is set by Docker Compose, so you do not need to change it.

- API: http://localhost:8000/api/v1
- Interactive docs (Swagger): http://localhost:8000/docs
- Database check: http://localhost:8000/bd/

New users get the **User** role. To make yourself Superadmin after your first login:

```bash
docker compose exec db psql -U pinfood -d pinfood \
  -c "UPDATE usuarios SET id_rol = 4 WHERE email = 'you@example.com';"
```

### Backend without Docker

Requirements: Python 3.12 and PostgreSQL with the PostGIS extension enabled (`CREATE EXTENSION postgis;`).

```bash
cd backendFastApi
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements-dev.txt
cp .env.example .env            # set DATABASE_URL and the rest
python scripts/init_db.py
uvicorn app.main:app --reload
```

### Flutter app

Requirements: Flutter SDK (Dart 3.11 or later) and an Android emulator or device.

```bash
cd frontendflutter
flutter pub get
flutter run
```

By default the app calls `http://10.0.2.2:8000/api/v1`, which is the host machine as seen from the Android emulator. To use another backend:

```bash
flutter run --dart-define=API_BASE_URL=http://<host>:8000/api/v1 \
            --dart-define=SHARE_BASE_URL=http://<host>:8000
```

Google Sign-In needs a Google Cloud project with OAuth clients for Android and web. The web client ID goes in `GOOGLE_WEB_CLIENT_ID` (backend) and in `googleWebClientId` in [`lib/core/constants.dart`](frontendflutter/lib/core/constants.dart).

## Environment variables

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string, e.g. `postgresql+psycopg2://user:pass@localhost:5432/pinfood` |
| `GOOGLE_WEB_CLIENT_ID` | Google OAuth web client ID, used to verify ID tokens |
| `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_API_KEY` / `CLOUDINARY_API_SECRET` | Cloudinary credentials for image uploads |

## Tests

```bash
cd backendFastApi
pip install -r requirements-dev.txt
pytest -v
```

The tests cover the restaurant schemas and CRUD layer (creation with and without coordinates, updates, deletion, average rating and the filtered search) using a mocked database session, so they need no database. They run on GitHub Actions on every push and pull request that touches the backend.

## Author

**Marcos Luque Montiel** · [LinkedIn](https://www.linkedin.com/in/marcos-luque-montiel-9202b93b1) · [GitHub](https://github.com/maarcoos8)
