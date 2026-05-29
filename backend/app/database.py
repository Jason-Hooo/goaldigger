# 檔案：backend/app/database.py

# 檔案：backend/app/database.py
import psycopg2
from fastapi import HTTPException, status
from psycopg2.extras import RealDictCursor
from psycopg2 import OperationalError
from .config import get_settings  

def get_db_connection():
    """Return a PostgreSQL connection for FastAPI dependency injection."""
    db_url = get_settings().db_url
    try:
        conn = psycopg2.connect(db_url, cursor_factory=RealDictCursor)
    except OperationalError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="資料庫目前無法連線，請稍後再試。",
        ) from exc
    try:
        yield conn
    finally:
        conn.close()  

# 💡 新增：給 Scheduler 使用的純連線函數
def get_raw_db_connection():
    """Return a plain PostgreSQL connection for background jobs."""
    db_url = get_settings().db_url
    try:
        return psycopg2.connect(db_url, cursor_factory=RealDictCursor)
    except OperationalError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="資料庫目前無法連線，請稍後再試。",
        ) from exc
