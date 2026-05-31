# GoalDigger

GoalDigger is a smart expense tracker built with Flutter and Supabase. It features daily budget calculation, visual goal tracking, and group split bills to help users achieve their financial goals.

## Features

- **Personal Ledger**: Track daily expenses and income with customizable categories
- **Goal Tracking**: Set financial goals with visual progress tracking and achievement system
- **Group Split Bills**: Create groups and split expenses among members
- **Real-time Sync**: Automatic updates across all connected devices using Supabase realtime
- **Daily Budget**: Automatic daily budget allocation based on goal progress
- **Achievement System**: Unlock achievements when goals are completed

## Tech Stack

### Frontend
- **Flutter**: Cross-platform mobile app framework
- **Supabase**: Backend-as-a-Service for database and realtime
- **Provider**: State management
- **Google Fonts**: Typography
- **QR Code**: QR code generation and scanning

### Backend
- **FastAPI**: Python web framework
- **PostgreSQL**: Database (via Supabase)
- **APScheduler**: Background job scheduling
- **psycopg2**: PostgreSQL adapter

## Project Structure

```
goaldigger/
├── backend/                 # Python FastAPI backend
│   ├── app/
│   │   ├── routers/       # API route handlers
│   │   ├── config.py      # Configuration management
│   │   ├── database.py    # Database connection
│   │   ├── scheduler.py   # Background jobs
│   │   └── schemas.py     # Pydantic models
│   ├── requirements.txt    # Python dependencies
│   └── .env.example       # Environment variables template
├── frontend/              # Flutter mobile app
│   └── goaldigger_app/
│       ├── lib/          # Dart source code
│       │   ├── views/    # UI screens
│       │   ├── models/   # Data models
│       │   ├── api/      # API client
│       │   └── services/ # Business logic
│       ├── pubspec.yaml  # Flutter dependencies
│       └── .env.example  # Environment variables template
└── README.md             # This file
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

Edit `.env` with your Supabase credentials (same as backend).

4. Run the app:
```bash
flutter run
```

## Database Schema

The application uses the following main tables:

- `users` - User accounts and authentication
- `expense_types` - Expense/income categories
- `personal_consumptions` - Personal ledger entries
- `goals` - Financial goals
- `achievements` - Goal achievements
- `groups` - Group split bill groups
- `group_members` - Group membership
- `group_consumptions` - Group expense headers
- `consumption_participants` - Group expense participant details

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
- `GET /goals/` - Get user goals
- `POST /goals/` - Create goal
- `PUT /goals/{goal_id}` - Update goal
- `DELETE /goals/{goal_id}` - Delete goal
- `POST /goals/{goal_id}/achieve` - Mark goal as achieved

### Split Bills
- `GET /splits/groups` - Get user groups
- `POST /splits/groups` - Create group
- `POST /splits/expenses` - Create split expense
- `PUT /splits/expenses/{consumption_id}` - Update split expense
- `DELETE /splits/expenses/{consumption_id}` - Delete split expense

## Development

### Backend Development

The backend uses FastAPI with automatic API documentation available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### Frontend Development

The Flutter app supports hot reload during development. Press `r` in the terminal to hot reload, or `R` to hot restart.

## License

This project is licensed under the terms specified in the LICENSE file.
