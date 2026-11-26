from fastapi import APIRouter, Depends
from ..database import get_db_connection
from psycopg2.extras import RealDictCursor

router = APIRouter(prefix="/stats", tags=["統計分析"])

@router.get("/category/{user_id}")
def get_category_stats(user_id: int, conn=Depends(get_db_connection)):
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # 使用 date_trunc 篩選當月資料，並 join expense_types 拿分類名稱
        query = """
            SELECT et.type_name AS category, SUM(pc.amount) AS amount
            FROM personal_consumptions pc
            JOIN expense_types et ON pc.type_id = et.type_id
            WHERE pc.user_id = %s
              AND date_trunc('month', pc.created_at) = date_trunc('month', CURRENT_DATE)
            GROUP BY et.type_name
            ORDER BY amount DESC;
        """
        cursor.execute(query, (user_id,))
        results = cursor.fetchall()
        
        # 轉型，確保 amount 是 float 以利前端解析
        return [{"category": r["category"], "amount": float(r["amount"])} for r in results]
    finally:
        cursor.close()


@router.get("/trend/{user_id}")
def get_trend_stats(user_id: int, days: int = 7, conn=Depends(get_db_connection)):
    """折線圖資料：觀察最近 7 天的花費趨勢"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # 按日期分組加總金額
        query = """
            SELECT DATE(created_at) AS date, SUM(amount) AS total_amount
            FROM personal_consumptions
            WHERE user_id = %s
              AND created_at >= CURRENT_DATE - (%s * INTERVAL '1 day')
            GROUP BY DATE(created_at)
            ORDER BY date ASC;
        """
        # 注意：INTERVAL 的參數拼接在 psycopg2 建議這樣寫避免 SQL injection
        cursor.execute(query, (user_id, days))
        results = cursor.fetchall()
        
        return [{"date": str(r["date"]), "total_amount": float(r["total_amount"])} for r in results]
    finally:
        cursor.close()
