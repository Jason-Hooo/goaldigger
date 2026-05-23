from fastapi import APIRouter, HTTPException, status
from typing import List, Optional
from database import get_db_connection
from schemas import LedgerCreate, LedgerResponse

router = APIRouter(prefix="/ledger", tags=["核心記帳"])


@router.post("/", response_model=LedgerResponse, status_code=status.HTTP_201_CREATED)
def create_consumption(item: LedgerCreate):
    """新增個人消費紀錄，若有綁定目標，則同步扣減目標累積金額。"""
    conn = next(get_db_connection())
    cursor = conn.cursor()

    try:
        insert_query = """
            INSERT INTO personal_consumptions
                (user_id, type_id, amount, description)
            VALUES
                (%s, %s, %s, %s)
            RETURNING
                consumption_id, user_id, type_id, amount, description, created_at;
        """

        cursor.execute(
            insert_query,
            (item.user_id, item.type_id, item.amount, item.description),
        )

        new_consumption = cursor.fetchone()

        if item.goal_id:
            update_goal_query = """
                UPDATE goals
                SET cumulative_amount = GREATEST(0, cumulative_amount - %s)
                WHERE goal_id = %s;
            """
            cursor.execute(update_goal_query, (item.amount, item.goal_id))

        conn.commit()
        return new_consumption

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"記帳失敗：{e}")

    finally:
        cursor.close()
        conn.close()


@router.get("/history/{user_id}", response_model=List[LedgerResponse])
def get_ledger_history(user_id: int, limit: int = 20):
    """查看使用者過去的支出詳情，預設回傳最新 20 筆。"""
    conn = next(get_db_connection())
    cursor = conn.cursor()

    try:
        query = """
            SELECT
                consumption_id, user_id, type_id, amount, description, created_at
            FROM personal_consumptions
            WHERE user_id = %s
            ORDER BY created_at DESC
            LIMIT %s;
        """

        cursor.execute(query, (user_id, limit))
        return cursor.fetchall()

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"獲取歷史紀錄失敗：{e}")

    finally:
        cursor.close()
        conn.close()


@router.delete("/{record_id}", status_code=status.HTTP_200_OK)
def delete_consumption(record_id: int, goal_id: Optional[int] = None):
    """刪除消費紀錄；若有指定 goal_id，則將金額補回目標累積金額。"""
    conn = next(get_db_connection())
    cursor = conn.cursor()

    try:
        cursor.execute(
            """
            SELECT amount
            FROM personal_consumptions
            WHERE consumption_id = %s;
            """,
            (record_id,),
        )

        record = cursor.fetchone()

        if not record:
            raise HTTPException(status_code=404, detail="找不到該筆消費紀錄")

        refund_amount = record["amount"]

        cursor.execute(
            """
            DELETE FROM personal_consumptions
            WHERE consumption_id = %s;
            """,
            (record_id,),
        )

        if goal_id:
            update_goal_query = """
                UPDATE goals
                SET cumulative_amount = cumulative_amount + %s
                WHERE goal_id = %s;
            """
            cursor.execute(update_goal_query, (refund_amount, goal_id))

        conn.commit()

        return {
            "status": "success",
            "message": f"已成功刪除，並補回目標進度 {refund_amount} 元"
        }

    except HTTPException:
        conn.rollback()
        raise

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"刪除紀錄失敗：{e}")

    finally:
        cursor.close()
        conn.close()