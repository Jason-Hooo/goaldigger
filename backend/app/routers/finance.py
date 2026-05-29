from fastapi import APIRouter, HTTPException, Depends, status
from typing import Optional
from ..database import get_db_connection
from ..schemas import FinanceSetupCreate
import calendar
from datetime import datetime

router = APIRouter(prefix="/finance", tags=["財務與預算設定"])

@router.get("/summary/{user_id}")
def get_finance_summary(user_id: int, month: Optional[str] = None, conn=Depends(get_db_connection)):
    """取得指定月份的每日可支配所得與固定支出總額。"""
    cursor = conn.cursor()
    try:
        record_month = month or datetime.now().strftime("%Y-%m")
        cursor.execute(
            """
            SELECT info_id, daily_usable_amount
            FROM monthly_financial_info
            WHERE user_id = %s AND record_month = %s;
            """,
            (user_id, record_month),
        )
        info = cursor.fetchone()
        if not info:
            return {
                "record_month": record_month,
                "daily_usable_amount": 0,
                "fixed_expense_total": 0,
            }

        cursor.execute(
            """
            SELECT COALESCE(SUM(amount), 0) AS total
            FROM fixed_money_flow
            WHERE info_id = %s;
            """,
            (info["info_id"],),
        )
        fixed_total = cursor.fetchone()["total"]

        return {
            "record_month": record_month,
            "daily_usable_amount": float(info["daily_usable_amount"]),
            "fixed_expense_total": float(fixed_total),
        }
    finally:
        cursor.close()

@router.post("/setup", status_code=status.HTTP_201_CREATED)
def setup_monthly_finance(data: FinanceSetupCreate, conn=Depends(get_db_connection)):
    """設定每月的固定收支，並自動計算『每日可支配所得』"""
    cursor = conn.cursor()
    try:
        # 1. 計算這個月有幾天 (例如 2026-05 有 31 天)
        year, month = map(int, data.record_month.split("-"))
        days_in_month = calendar.monthrange(year, month)[1]

        # 2. 計算總固定支出
        total_fixed_expense = sum(item.amount for item in data.fixed_flows)

        # 3. 計算每日可支配所得 (總預算 - 總固定支出) / 天數
        daily_usable = (data.monthly_income - total_fixed_expense) / days_in_month
        if daily_usable < 0:
            daily_usable = 0 # 防呆：避免變成負數

        # 4. 寫入 monthly_financial_info 表
        cursor.execute(
            """
            INSERT INTO monthly_financial_info (user_id, record_month, daily_usable_amount)
            VALUES (%s, %s, %s)
            RETURNING info_id;
            """,
            (data.user_id, data.record_month, daily_usable)
        )
        info_id = cursor.fetchone()["info_id"]

        # 5. 寫入 fixed_money_flow 表 (多筆新增)
        if data.fixed_flows:
            flow_records = [(info_id, f.category, f.description, f.amount) for f in data.fixed_flows]
            cursor.executemany(
                "INSERT INTO fixed_money_flow (info_id, category, description, amount) VALUES (%s, %s, %s, %s);",
                flow_records
            )

        conn.commit()
        return {
            "status": "success", 
            "message": "預算設定完成！", 
            "daily_usable_amount": round(daily_usable, 2)
        }

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"設定財務資訊失敗: {e}")
    finally:
        cursor.close()