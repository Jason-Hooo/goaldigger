from fastapi import APIRouter, HTTPException, Depends, status
from typing import List, Optional
from database import get_db_connection
from schemas import LedgerCreate, LedgerResponse
from psycopg2.extras import RealDictCursor
from datetime import datetime

router = APIRouter(prefix="/ledger", tags=["核心記帳"])

@router.post("/", response_model=dict, status_code=status.HTTP_201_CREATED)
def create_consumption(ledger_data: LedgerCreate, conn = Depends(get_db_connection)):
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # 1. 確認這筆消費類別是「支出」還是「收入」
        cursor.execute("SELECT is_expense FROM expense_types WHERE type_id = %s;", (ledger_data.type_id,))
        type_row = cursor.fetchone()
        is_expense = type_row['is_expense'] if type_row else True 

        # 2. 如果是支出，執行預算邏輯
        if is_expense:
            # 取得今日預算上限
            cursor.execute("""
                SELECT daily_usable_amount FROM monthly_financial_info 
                WHERE user_id = %s AND record_month = TO_CHAR(CURRENT_DATE, 'YYYY-MM');
            """, (ledger_data.user_id,))
            budget_row = cursor.fetchone()
            daily_limit = budget_row['daily_usable_amount'] if budget_row else 0

            # 取得今日已花費總額
            cursor.execute("""
                SELECT COALESCE(SUM(amount), 0) as total_spent FROM personal_consumptions 
                WHERE user_id = %s AND created_at::date = CURRENT_DATE;
            """, (ledger_data.user_id,))
            today_spent = cursor.fetchone()['total_spent']

            # 3. 判斷是否超支 (Over-budget)
            remaining_budget = float(daily_limit) - float(today_spent)
            if ledger_data.amount > remaining_budget:
                excess_amount = float(ledger_data.amount) - max(0, remaining_budget)
                # 只有超支部分才扣目標錢
                cursor.execute("""
                    UPDATE goals SET cumulative_amount = cumulative_amount - %s 
                    WHERE goal_id = %s;
                """, (excess_amount, ledger_data.goal_id))
                print(f"[{datetime.now()}] 超支警報！從目標扣除了 {excess_amount} 元")

        # 4. 新增消費記錄 (不管是否超支都要存)
        cursor.execute("""
            INSERT INTO personal_consumptions (user_id, type_id, amount, description, goal_id)
            VALUES (%s, %s, %s, %s, %s);
        """, (ledger_data.user_id, ledger_data.type_id, ledger_data.amount, ledger_data.description, ledger_data.goal_id))
        
        conn.commit()
        return {"status": "success", "message": "記帳完成！"}

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=f"記帳失敗: {str(e)}")
    finally:
        cursor.close()

@router.get("/history/{user_id}", response_model=List[LedgerResponse])
def get_ledger_history(user_id: int, limit: int = 20, conn=Depends(get_db_connection)):
    """查看使用者過去的支出詳情，預設回傳最新 20 筆。"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        query = "SELECT * FROM personal_consumptions WHERE user_id = %s ORDER BY created_at DESC LIMIT %s;"
        cursor.execute(query, (user_id, limit))
        return cursor.fetchall()
    finally:
        cursor.close()

@router.delete("/{record_id}", status_code=status.HTTP_200_OK)
def delete_consumption(record_id: int, goal_id: Optional[int] = None, conn=Depends(get_db_connection)):
    """刪除消費紀錄，並完美將進度校正回來。"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # 撈出金額與種類名稱
        cursor.execute("""
            SELECT pc.amount, et.type_name 
            FROM personal_consumptions pc
            JOIN expense_types et ON pc.type_id = et.type_id
            WHERE pc.consumption_id = %s;
        """, (record_id,))
        record = cursor.fetchone()
        if not record:
            raise HTTPException(status_code=404, detail="找不到該筆消費紀錄")

        refund_amount = record["amount"]
        is_income = (record["type_name"] == "額外收入")

        # 刪除紀錄
        cursor.execute("DELETE FROM personal_consumptions WHERE consumption_id = %s;", (record_id,))

        if goal_id:
            if is_income:
                # 刪除收入 = 進度要扣回來
                update_goal_query = "UPDATE goals SET cumulative_amount = GREATEST(0, cumulative_amount - %s) WHERE goal_id = %s;"
            else:
                # 刪除支出 = 進度補回來
                update_goal_query = "UPDATE goals SET cumulative_amount = cumulative_amount + %s WHERE goal_id = %s;"
            cursor.execute(update_goal_query, (refund_amount, goal_id))

        conn.commit()
        return {"status": "success", "message": "已成功刪除並同步校正目標進度"}
    except HTTPException:
        conn.rollback()
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"刪除紀錄失敗：{e}")
    finally:
        cursor.close()
