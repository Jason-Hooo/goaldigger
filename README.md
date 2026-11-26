# GoalDigger

GoalDigger is a smart expense tracker built with Flutter and Supabase. It features visual goal tracking and group split bills to help users achieve their financial goals.

## Features

- **Personal Ledger**: Track daily expenses and income with customizable categories
- **Goal Tracking**: Set financial goals with visual progress tracking and achievement system
- **Group Split Bills**: Create groups and split expenses among members
- **Real-time Sync**: Automatic updates across all connected devices using Supabase realtime
- **Achievement System**: Unlock achievements when goals are completed

## Tech Stack

<table>
<tr>
<th>Frontend</th>
<th>Backend</th>
</tr>
<tr>
<td valign="top">

- **Flutter**: Cross-platform app (MVVM)
- **Provider**: State management & DI
- **http**: REST client
- **Supabase Realtime**: Live sync
- **qr_flutter / mobile_scanner**: Group invite QR codes
- **google_fonts**: Typography

</td>
<td valign="top">

- **FastAPI + Uvicorn**: REST API
- **Pydantic**: Validation & settings
- **PostgreSQL (Supabase)**: Database
- **psycopg2**: Raw SQL access
- **bcrypt**: Password hashing

</td>
</tr>
</table>

## Database Schema

![GoalDigger ERD](docs/goaldigger_erd.svg)

## Project Structure

```
goaldigger/
├── backend/                            # Python FastAPI backend
│   ├── app/
│   │   ├── routers/                    # API route handlers
│   │   │   ├── auth.py
│   │   │   ├── goals.py
│   │   │   ├── ledger.py
│   │   │   ├── splits.py
│   │   │   └── stats.py
│   │   ├── config.py                   # Configuration management
│   │   ├── database.py                 # Database connection
│   │   ├── main.py                     # FastAPI entry point
│   │   ├── models.py                   # DB schema reference (SQL, not executable)
│   │   └── schemas.py                  # Pydantic schemas
│   ├── .env.example                    # Environment variables template
│   └── requirements.txt                # Python dependencies
├── docs/
│   ├── goaldigger_erd.drawio           # ER diagram (draw.io source)
│   └── goaldigger_erd.svg              # ER diagram (image)
├── frontend/
│   └── goaldigger_app/                 # Flutter app
│       ├── android/
│       ├── ios/
│       ├── lib/                        # Dart source code (MVVM)
│       │   ├── app/                    # App root & dependency wiring
│       │   ├── core/                   # Shared infrastructure
│       │   │   ├── config/             # App configuration
│       │   │   ├── errors/             # Exception types
│       │   │   ├── result/             # Result type
│       │   │   ├── theme/              # Colors & theme
│       │   │   └── utils/              # Formatters, validators, helpers
│       │   ├── data/                   # Data layer
│       │   │   ├── models/             # Data models
│       │   │   ├── repositories/       # Repositories
│       │   │   └── services/           # API & realtime services
│       │   ├── ui/                     # Feature screens (views, view models, widgets)
│       │   └── main.dart               # App entry point
│       ├── linux/
│       ├── macos/
│       ├── test/
│       ├── web/
│       ├── windows/
│       ├── .env.example                # Environment variables template
│       ├── .metadata
│       ├── analysis_options.yaml
│       ├── ARCHITECTURE.md             # Frontend architecture notes
│       ├── devtools_options.yaml
│       └── pubspec.yaml                # Flutter dependencies
├── .gitignore
├── LICENSE
└── README.md
```

## Setup Instructions

### Backend Setup

1. Navigate to the backend directory:
```bash
cd backend
```

2. Create a virtual environment:
```bash
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Configure environment variables:
```bash
cp .env.example .env
```

Edit `.env` with your Supabase credentials:
```
SUPABASE_URL="https://your-project.supabase.co/rest/v1/"
DB_URL="postgresql://postgres:your-password@db.your-project.supabase.co:5432/postgres"
SUPABASE_ANON_KEY="your-supabase-anon-key"
```

5. Run the backend server:
```bash
uvicorn app.main:app --reload
```

To allow physical devices on your network to connect, bind to all interfaces:
```bash
uvicorn app.main:app --reload --host 0.0.0.0
```

### Frontend Setup

1. Navigate to the frontend directory:
```bash
cd frontend/goaldigger_app
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Configure environment variables:
```bash
cp .env.example .env
```

Edit `.env` with your Supabase URL / anon key and the backend address:
```
SUPABASE_URL="https://your-project.supabase.co"
SUPABASE_ANON_KEY="your-supabase-anon-key"
API_BASE_URL="http://localhost:8000"
```

`API_BASE_URL` depends on where the app runs:
- iOS simulator / macOS / Web / Windows: `http://localhost:8000`
- Android emulator: `http://10.0.2.2:8000`
- Physical device (same Wi-Fi): `http://<your-computer-LAN-IP>:8000`

4. Run the app:
```bash
flutter run
```

## API Endpoints

### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login user

### Ledger
- `GET /ledger/types` - Get expense types
- `POST /ledger/types` - Create custom expense type
- `PUT /ledger/types/{type_id}` - Update expense type
- `DELETE /ledger/types/{type_id}` - Delete expense type
- `POST /ledger/` - Create ledger entry
- `PUT /ledger/{record_id}` - Update ledger entry
- `DELETE /ledger/{record_id}` - Delete ledger entry
- `GET /ledger/history/{user_id}` - Get ledger history

### Goals
- `GET /goals/{user_id}` - Get user goals
- `POST /goals/` - Create goal
- `PUT /goals/{goal_id}` - Update goal
- `DELETE /goals/{goal_id}` - Delete goal
- `POST /goals/achieve/{goal_id}` - Mark goal as achieved

### Stats
- `GET /stats/category/{user_id}` - Get spending by category

### Split Bills
- `GET /splits/groups/{user_id}` - Get user groups
- `POST /splits/groups/` - Create group
- `POST /splits/groups/join-by-code` - Join group by invite code
- `GET /splits/groups/{group_id}/members` - Get group members
- `DELETE /splits/groups/{group_id}/members/{user_id}` - Leave group
- `GET /splits/expenses/{user_id}` - Get user split expenses
- `POST /splits/expenses/create` - Create split expense
- `PUT /splits/expenses/{consumption_id}` - Update split expense
- `DELETE /splits/expenses/{consumption_id}` - Delete split expense
- `PUT /splits/expenses/{consumption_id}/participants/{user_id}/status` - Update participant payment status
- `GET /splits/settle/{group_id}` - Settle group expenses

## Development

### Backend Development

The backend uses FastAPI with automatic API documentation available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### Frontend Development

The Flutter app supports hot reload during development. Press `r` in the terminal to hot reload, or `R` to hot restart.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
