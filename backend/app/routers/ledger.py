from fastapi import APIRouter, HTTPException, Depends, status
from typing import List, Optional
from ..database import get_db_connection
from ..schemas import ExpenseTypeCreate, ExpenseTypeUpdate, LedgerCreate, LedgerResponse, LedgerUpdate
from psycopg2.extras import RealDictCursor
from datetime import datetime

router = APIRouter(prefix="/ledger", tags=["核心記帳"])


def _adjust_goal_progress(cursor, goal_id: Optional[int], delta: float) -> Optional[dict]:
    """Adjust goal progress by a signed delta, clamping at zero.

    If the goal's cumulative amount reaches or exceeds the target amount,
    insert a row into `achievements` (if not already present) using the same
    DB transaction. Returns the inserted/found achievement row or ``None``.
    """
    if goal_id is None or delta == 0:
        return None

    # Update the goal's cumulative_amount (clamped at zero)
    cursor.execute(
        """
        UPDATE goals
        SET cumulative_amount = GREATEST(COALESCE(cumulative_amount, 0) + %s, 0)
        WHERE goal_id = %s;
        """,
        (delta, goal_id),
    )

    # Re-read the goal to determine if it has reached the target
    cursor.execute(
        "SELECT cumulative_amount, target_amount FROM goals WHERE goal_id = %s;",
        (goal_id,),
    )
    goal_row = cursor.fetchone()
    if not goal_row:
        return None

    cum = goal_row.get("cumulative_amount")
    target = goal_row.get("target_amount")
    try:
        if cum is not None and target is not None and float(cum) >= float(target):
            cursor.execute(
                """
                INSERT INTO achievements (goal_id, completion_date)
                VALUES (%s, CURRENT_TIMESTAMP)
                ON CONFLICT (goal_id) DO NOTHING
                RETURNING goal_id, completion_date;
                """,
                (goal_id,),
            )
            achieved = cursor.fetchone()
            if achieved:
                return achieved

            # If no row was returned (already existed), fetch the existing achievement
            cursor.execute(
                "SELECT goal_id, completion_date FROM achievements WHERE goal_id = %s;",
                (goal_id,),
            )
            return cursor.fetchone()
    except Exception:
        # Do not let achievement insert failures break the calling flow;
        # caller will commit/rollback as appropriate.
        return None

    return None

@router.get("/types")
def get_expense_types(user_id: Optional[int] = None, conn=Depends(get_db_connection)):
    """取得系統內建與使用者自訂的記帳類別。"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cursor.execute(
            """
            SELECT type_id, type_name, is_expense, user_id
            FROM expense_types
            WHERE user_id IS NULL OR user_id = %s
            ORDER BY CASE WHEN user_id IS NULL THEN 0 ELSE 1 END, type_id ASC;
            """
            , (user_id,)
        )
        return cursor.fetchall()
    finally:
        cursor.close()


@router.post("/types", status_code=status.HTTP_201_CREATED)
def create_expense_type(type_data: ExpenseTypeCreate, conn=Depends(get_db_connection)):
    """建立使用者自訂記帳類別。"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        type_name = type_data.type_name.strip()
        cursor.execute(
            """
            SELECT type_id
            FROM expense_types
            WHERE LOWER(type_name) = LOWER(%s)
              AND is_expense = %s
              AND COALESCE(user_id, -1) = COALESCE(%s, -1);
            """,
            (type_name, type_data.is_expense, type_data.user_id),
        )
        existing = cursor.fetchone()
        if existing:
            raise HTTPException(status_code=409, detail="相同類別已存在")

        cursor.execute(
            """
            SELECT setval(
                pg_get_serial_sequence('expense_types', 'type_id'),
                COALESCE((SELECT MAX(type_id) FROM expense_types), 0)
            );
            """
        )

        cursor.execute(
            """
            INSERT INTO expense_types (type_name, is_expense, user_id)
            VALUES (%s, %s, %s)
            RETURNING type_id, type_name, is_expense, user_id;
            """,
            (type_name, type_data.is_expense, type_data.user_id),
        )
        created = cursor.fetchone()
        conn.commit()
        return {"status": "success", "data": created}
    except HTTPException:
        conn.rollback()
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"新增類別失敗: {e}")
    finally:
        cursor.close()


@router.put("/types/{type_id}")
def update_expense_type(type_id: int, type_data: ExpenseTypeUpdate, conn=Depends(get_db_connection)):
    """更新使用者自訂記帳類別。"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cursor.execute(
            """
            SELECT type_id, user_id
            FROM expense_types
            WHERE type_id = %s;
            """,
            (type_id,),
        )
        existing = cursor.fetchone()
        if not existing:
          raise HTTPException(status_code=404, detail="找不到該類別")
        if existing["user_id"] is None:
          raise HTTPException(status_code=403, detail="系統內建類別不可修改")
        if existing["user_id"] != type_data.user_id:
          raise HTTPException(status_code=403, detail="你沒有權限修改這個類別")

        normalized_name = type_data.type_name.strip()
        cursor.execute(
            """
            SELECT type_id
            FROM expense_types
            WHERE type_id <> %s
              AND LOWER(type_name) = LOWER(%s)
              AND is_expense = %s
              AND COALESCE(user_id, -1) = %s;
            """,
            (type_id, normalized_name, type_data.is_expense, type_data.user_id),
        )
        conflict = cursor.fetchone()
        if conflict:
            raise HTTPException(status_code=409, detail="相同類別已存在")

        cursor.execute(
            """
            UPDATE expense_types
            SET type_name = %s,
                is_expense = %s
            WHERE type_id = %s
            RETURNING type_id, type_name, is_expense, user_id;
            """,
            (normalized_name, type_data.is_expense, type_id),
        )
        updated = cursor.fetchone()
        conn.commit()
        return {"status": "success", "data": updated}
    except HTTPException:
        conn.rollback()
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"更新類別失敗: {e}")
    finally:
        cursor.close()


@router.delete("/types/{type_id}", status_code=status.HTTP_200_OK)
def delete_expense_type(type_id: int, user_id: int, conn=Depends(get_db_connection)):
    """刪除使用者自訂記帳類別。"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cursor.execute(
            """
            SELECT type_id, user_id
            FROM expense_types
            WHERE type_id = %s;
            """,
            (type_id,),
        )
        existing = cursor.fetchone()
        if not existing:
            raise HTTPException(status_code=404, detail="找不到該類別")
        if existing["user_id"] is None:
            raise HTTPException(status_code=403, detail="系統內建類別不可刪除")
        if existing["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="你沒有權限刪除這個類別")

        cursor.execute(
            """
            SELECT COUNT(*) AS usage_count
            FROM personal_consumptions
            WHERE type_id = %s;
            """,
            (type_id,),
        )
        usage_row = cursor.fetchone()
        if (usage_row["usage_count"] or 0) > 0:
            raise HTTPException(status_code=409, detail="此類別已有記帳紀錄，無法刪除")

        cursor.execute(
            "DELETE FROM expense_types WHERE type_id = %s RETURNING type_id;",
            (type_id,),
        )
        deleted = cursor.fetchone()
        conn.commit()
        return {"status": "success", "data": deleted}
    except HTTPException:
        conn.rollback()
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"刪除類別失敗: {e}")
    finally:
        cursor.close()

@router.post("/", response_model=dict, status_code=status.HTTP_201_CREATED)
def create_consumption(ledger_data: LedgerCreate, conn = Depends(get_db_connection)):
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # 1. 確認類別是系統內建或該使用者自訂
        cursor.execute(
            """
            SELECT is_expense
            FROM expense_types
            WHERE type_id = %s
              AND (user_id IS NULL OR user_id = %s);
            """,
            (ledger_data.type_id, ledger_data.user_id),
        )
        type_row = cursor.fetchone()
        if not type_row:
            raise HTTPException(status_code=404, detail="找不到可用的記帳類別")
        is_expense = type_row['is_expense']

        # Budget checking logic removed as monthly_financial_info table has been removed

        # 4. 新增消費記錄 (不管是否超支都要存)
        cursor.execute("""
            INSERT INTO personal_consumptions (user_id, type_id, amount, description, goal_id)
            VALUES (%s, %s, %s, %s, %s);
        """, (ledger_data.user_id, ledger_data.type_id, ledger_data.amount, ledger_data.description, ledger_data.goal_id))

        _adjust_goal_progress(cursor, ledger_data.goal_id, float(ledger_data.amount))
        
        conn.commit()
        return {"status": "success", "message": "記帳完成！"}

    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=f"記帳失敗: {str(e)}")
    finally:
        cursor.close()


@router.put("/{record_id}", response_model=dict)
def update_consumption(record_id: int, ledger_data: LedgerUpdate, conn=Depends(get_db_connection)):
    """更新單筆記帳紀錄。"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cursor.execute(
            """
            SELECT consumption_id, amount, goal_id
            FROM personal_consumptions
            WHERE consumption_id = %s AND user_id = %s;
            """,
            (record_id, ledger_data.user_id),
        )
        existing = cursor.fetchone()
        if not existing:
            raise HTTPException(status_code=404, detail="找不到該筆記帳紀錄")
        previous_amount = float(existing["amount"])
        previous_goal_id = existing["goal_id"]

        cursor.execute(
            """
            SELECT is_expense
            FROM expense_types
            WHERE type_id = %s
              AND (user_id IS NULL OR user_id = %s);
            """,
            (ledger_data.type_id, ledger_data.user_id),
        )
        type_row = cursor.fetchone()
        if not type_row:
            raise HTTPException(status_code=404, detail="找不到可用的記帳類別")

        cursor.execute(
            """
            UPDATE personal_consumptions
            SET type_id = %s,
                amount = %s,
                description = %s,
                goal_id = %s
            WHERE consumption_id = %s
            RETURNING consumption_id, user_id, type_id, amount, description, created_at, goal_id;
            """,
            (
                ledger_data.type_id,
                ledger_data.amount,
                ledger_data.description,
                ledger_data.goal_id,
                record_id,
            ),
        )
        updated = cursor.fetchone()

        if previous_goal_id == ledger_data.goal_id:
            _adjust_goal_progress(cursor, ledger_data.goal_id, float(ledger_data.amount) - previous_amount)
        else:
            _adjust_goal_progress(cursor, previous_goal_id, -previous_amount)
            _adjust_goal_progress(cursor, ledger_data.goal_id, float(ledger_data.amount))

        conn.commit()
        return {"status": "success", "message": "記帳已更新", "data": updated}
    except HTTPException:
        conn.rollback()
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"更新記帳失敗: {e}")
    finally:
        cursor.close()

@router.get("/history/{user_id}", response_model=List[LedgerResponse])
def get_ledger_history(user_id: int, limit: int = 20, conn=Depends(get_db_connection)):
    """查看使用者過去的支出詳情，預設回傳最新 20 筆。"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        query = """
            SELECT pc.*, et.type_name, et.is_expense
            FROM personal_consumptions pc
            JOIN expense_types et ON pc.type_id = et.type_id
            WHERE pc.user_id = %s
            ORDER BY pc.created_at DESC
            LIMIT %s;
        """
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
            SELECT pc.amount, pc.goal_id, et.type_name 
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

        target_goal_id = goal_id if goal_id is not None else record["goal_id"]
        _adjust_goal_progress(cursor, target_goal_id, -float(refund_amount))

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
