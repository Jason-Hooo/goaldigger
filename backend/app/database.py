# 檔案：backend/app/database.py

# 檔案：backend/app/database.py
import psycopg2
from psycopg2.extras import RealDictCursor
from config import get_settings  

settings = get_settings()
DB_URL = settings.db_url 

# 給 FastAPI 使用的 Generator (保持不變)
def get_db_connection():
    conn = psycopg2.connect(DB_URL, cursor_factory=RealDictCursor)
    try:
        yield conn
    finally:
        conn.close()  

# 💡 新增：給 Scheduler 使用的純連線函數
def get_raw_db_connection():
    return psycopg2.connect(DB_URL, cursor_factory=RealDictCursor)
