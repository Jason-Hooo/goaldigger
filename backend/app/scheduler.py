from .database import get_db_connection
from .database import get_raw_db_connection
from psycopg2.extras import RealDictCursor
from datetime import datetime

def allocate_daily_budget():
    """【方案 B 核心】每日凌晨自動將當日的可支配所得（花費標準）存入活躍目標中"""
    print(f"[{datetime.now()}] 開始自動發放今日可支配所得至活躍目標條...")
    # This function is disabled as monthly_financial_info table has been removed
    print(f"[{datetime.now()}] 每日預算發放功能已停用（monthly_financial_info 表已移除）")

# ==========================================
# 3. 每日結算：省下的錢轉為目標進度
# ==========================================
def reward_daily_savings():
    """每日結算：若今日支出 < 每日預算，將差額獎勵至目標進度中"""
    print(f"[{datetime.now()}] 啟動每日結算儲蓄獎勵機制...")
    # This function is disabled as monthly_financial_info table has been removed
    print(f"[{datetime.now()}] 每日結算獎勵功能已停用（monthly_financial_info 表已移除）")

