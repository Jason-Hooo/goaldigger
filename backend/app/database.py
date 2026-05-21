# 檔案：backend/app/database.py

import psycopg2
from psycopg2.extras import RealDictCursor
from config import get_settings  

# 2. 向秘書索取設定資訊
settings = get_settings()
DB_URL = settings.db_url  # 讓 Pydantic 去 .env 撈出 DB_URL

# 3. 獲取資料庫連線的函數
def get_db_connection():
    conn = psycopg2.connect(DB_URL, cursor_factory=RealDictCursor)
    try:
        yield conn
    finally:
        conn.close()  