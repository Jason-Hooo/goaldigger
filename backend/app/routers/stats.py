from fastapi import APIRouter, HTTPException, Depends
from ..database import get_db_connection
from psycopg2.extras import RealDictCursor
from typing import List

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
              AND created_at >= CURRENT_DATE - INTERVAL '%s days'
            GROUP BY DATE(created_at)
            ORDER BY date ASC;
        """
        # 注意：INTERVAL 的參數拼接在 psycopg2 建議這樣寫避免 SQL injection
        cursor.execute(query, (user_id, days))
        results = cursor.fetchall()
        
        return [{"date": str(r["date"]), "total_amount": float(r["total_amount"])} for r in results]
    finally:
        cursor.close()


@router.get("/overview/{user_id}")
def get_overview(user_id: int, conn=Depends(get_db_connection)):
    """首頁總覽：本月總花費 & 目前活躍目標達成率"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # 1. 撈本月總花費
        spend_query = """
            SELECT SUM(amount) AS current_month_spent
            FROM personal_consumptions
            WHERE user_id = %s
              AND date_trunc('month', created_at) = date_trunc('month', CURRENT_DATE);
        """
        cursor.execute(spend_query, (user_id,))
        spend_result = cursor.fetchone()
        month_spent = float(spend_result["current_month_spent"] or 0)

        # 2. 撈活躍目標 (從 goals 找，並且不在 achievements 裡面的)
        goal_query = """
            SELECT g.goal_name, g.target_amount, g.cumulative_amount
            FROM goals g
            LEFT JOIN achievements a ON g.goal_id = a.goal_id
            WHERE g.user_id = %s AND a.goal_id IS NULL
            LIMIT 1;
        """
        cursor.execute(goal_query, (user_id,))
        active_goal = cursor.fetchone()

        # 整理進度回傳格式
        goal_data = None
        if active_goal:
            target = float(active_goal["target_amount"])
            cumulative = float(active_goal["cumulative_amount"])
            progress_rate = round((cumulative / target) * 100, 2) if target > 0 else 0
            
            goal_data = {
                "goal_name": active_goal["goal_name"],
                "target_amount": target,
                "cumulative_amount": cumulative,
                "progress_rate_percent": progress_rate
            }

        return {
            "current_month_spent": month_spent,
            "active_goal": goal_data
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"獲取首頁總覽失敗: {e}")
    finally:
        cursor.close()