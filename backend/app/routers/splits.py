from fastapi import APIRouter, HTTPException, Depends, status, Query
from typing import List, Dict, Optional
from pydantic import BaseModel
import secrets
import string
from ..database import get_db_connection
from psycopg2.extras import RealDictCursor
from ..schemas import GroupCreate, GroupMemberAdd, ExpenseCreate

router = APIRouter(prefix="/splits", tags=["分帳管理"])


def generate_invitation_code():
    """Generate a unique 6-character invitation code."""
    alphabet = string.ascii_uppercase + string.digits
    while True:
        code = ''.join(secrets.choice(alphabet) for _ in range(6))
        # Check if code already exists
        # This will be checked in the create_group function
        return code


def _resolve_personal_type_id(cursor, type_id: Optional[int]) -> int:
    """Return a valid expense type id for mirrored personal consumptions."""
    if type_id is not None:
        cursor.execute(
            "SELECT type_id FROM expense_types WHERE type_id = %s;",
            (type_id,)
        )
        existing = cursor.fetchone()
        if existing:
            return existing["type_id"]
        raise HTTPException(status_code=400, detail="找不到對應的支出類別")

    cursor.execute(
        """
        SELECT type_id
        FROM expense_types
        WHERE is_expense = TRUE
        ORDER BY CASE WHEN user_id IS NULL THEN 0 ELSE 1 END, type_id ASC
        LIMIT 1;
        """
    )
    fallback = cursor.fetchone()
    if not fallback:
        raise HTTPException(status_code=400, detail="找不到可用的支出類別，請先建立 expense type")

    return fallback["type_id"]


def _build_personal_consumption_records(cursor, expense: ExpenseCreate, group_consumption_id: int):
    """Build mirrored personal consumption rows for a group expense."""
    records = []
    type_id = _resolve_personal_type_id(cursor, expense.type_id)

    for detail in expense.split_details:
        if detail.shared_amount <= 0:
            continue

        records.append(
            (
                detail.user_id,
                type_id,
                detail.shared_amount,
                f"{expense.name} (群組分帳)",
                group_consumption_id,
            )
        )

    return records


def _sync_personal_consumptions(cursor, expense: ExpenseCreate, group_consumption_id: int):
    """Replace mirrored personal consumption rows for a group expense."""
    cursor.execute(
        "DELETE FROM personal_consumptions WHERE group_consumption_id = %s;",
        (group_consumption_id,)
    )

    personal_records = _build_personal_consumption_records(cursor, expense, group_consumption_id)
    if personal_records:
        cursor.executemany(
            """
            INSERT INTO personal_consumptions
            (user_id, type_id, amount, description, created_at, group_consumption_id)
            VALUES (%s, %s, %s, %s, NOW(), %s);
            """,
            personal_records
        )


@router.post("/groups/", status_code=status.HTTP_201_CREATED)
def create_group(group: GroupCreate, conn=Depends(get_db_connection)):
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # Generate a unique invitation code
        invitation_code = generate_invitation_code()

        # 1. 建立群組
        cursor.execute(
            "INSERT INTO groups_table (group_name, invitation_code) VALUES (%s, %s) RETURNING group_id, group_name, invitation_code;",
            (group.group_name, invitation_code)
        )
        new_group = cursor.fetchone()

        # 2. 將成員加入 group_members 表
        member_records = [(new_group['group_id'], uid) for uid in group.user_ids]
        cursor.executemany(
            "INSERT INTO group_members (group_id, user_id) VALUES (%s, %s);",
            member_records
        )

        conn.commit()
        return {"status": "success", "data": new_group}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"建立群組失敗: {e}")
    finally:
        cursor.close()

@router.get("/groups/{user_id}")
def get_user_groups(user_id: int, conn=Depends(get_db_connection)):
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        query = """
            SELECT g.group_id, g.group_name, g.invitation_code, g.created_at
            FROM groups_table g
            JOIN group_members gm ON g.group_id = gm.group_id
            WHERE gm.user_id = %s
            ORDER BY g.created_at DESC;
        """
        cursor.execute(query, (user_id,))
        return cursor.fetchall()
    finally:
        cursor.close()

@router.post("/groups/join-by-code", status_code=status.HTTP_200_OK)
def join_group_by_code(payload: dict, conn=Depends(get_db_connection)):
    """加入群組 by invitation code."""
    invitation_code = payload.get('invitation_code')
    user_id = payload.get('user_id')

    if not invitation_code or not user_id:
        raise HTTPException(status_code=400, detail="請提供邀請碼和使用者 ID")

    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # Find the group by invitation code
        cursor.execute(
            "SELECT group_id FROM groups_table WHERE invitation_code = %s;",
            (invitation_code,)
        )
        group = cursor.fetchone()

        if not group:
            raise HTTPException(status_code=404, detail="找不到此邀請碼對應的群組")

        # Check if user is already in the group
        cursor.execute(
            "SELECT 1 FROM group_members WHERE group_id = %s AND user_id = %s;",
            (group['group_id'], user_id)
        )
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="你已經在此群組中")

        # Add user to group
        cursor.execute(
            "INSERT INTO group_members (group_id, user_id) VALUES (%s, %s);",
            (group['group_id'], user_id)
        )

        conn.commit()
        return {"status": "success", "message": "已成功加入群組", "group_id": group['group_id']}
    except HTTPException:
        conn.rollback()
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"加入群組失敗: {e}")
    finally:
        cursor.close()

@router.post("/groups/{group_id}/members", status_code=status.HTTP_200_OK)
def add_group_members(group_id: int, payload: GroupMemberAdd, conn=Depends(get_db_connection)):
    """加入現有群組成員。"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        member_records = [(group_id, uid) for uid in payload.user_ids]
        cursor.executemany(
            "INSERT INTO group_members (group_id, user_id) VALUES (%s, %s) ON CONFLICT DO NOTHING;",
            member_records,
        )
        conn.commit()
        return {"status": "success", "message": "已加入群組"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"加入群組失敗: {e}")
    finally:
        cursor.close()

@router.get("/groups/{group_id}/members", status_code=status.HTTP_200_OK)
def get_group_members(group_id: int, conn=Depends(get_db_connection)):
    """取得群組成員列表。"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        query = """
            SELECT u.user_id, u.name AS user_name
            FROM group_members gm
            JOIN users u ON gm.user_id = u.user_id
            WHERE gm.group_id = %s
            ORDER BY u.name;
        """
        cursor.execute(query, (group_id,))
        return cursor.fetchall()
    finally:
        cursor.close()

@router.delete("/groups/{group_id}/members/{user_id}", status_code=status.HTTP_200_OK)
def leave_group(group_id: int, user_id: int, conn=Depends(get_db_connection)):
    """退出群組。"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cursor.execute(
            "DELETE FROM group_members WHERE group_id = %s AND user_id = %s;",
            (group_id, user_id)
        )
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="找不到該成員記錄")
        conn.commit()
        return {"status": "success", "message": "已退出群組"}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"退出群組失敗: {e}")
    finally:
        cursor.close()

@router.put("/expenses/{consumption_id}/participants/{user_id}/status", status_code=status.HTTP_200_OK)
def update_participant_status(consumption_id: int, user_id: int, status: str = Query(...), conn=Depends(get_db_connection)):
    """更新參與者的還款狀態。"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cursor.execute(
            """
            UPDATE consumption_participants
            SET status = %s
            WHERE consumption_id = %s AND user_id = %s;
            """,
            (status, consumption_id, user_id)
        )
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="找不到該參與者記錄")
        conn.commit()
        return {"status": "success", "message": "已更新還款狀態"}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"更新還款狀態失敗: {e}")
    finally:
        cursor.close()

@router.get("/expenses/{user_id}")
def get_user_expenses(user_id: int, conn=Depends(get_db_connection)):
    """取得使用者參與的群組分帳紀錄。"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        query = """
            SELECT gc.consumption_id,
                   gc.group_id,
                   g.group_name,
                   gc.name,
                   gc.amount,
                   gc.created_at,
                   cp.user_id,
                   cp.shared_amount,
                   cp.is_payer,
                   cp.status,
                   u.name AS user_name
            FROM group_consumptions gc
            JOIN groups_table g ON gc.group_id = g.group_id
            JOIN consumption_participants cp ON cp.consumption_id = gc.consumption_id
            JOIN users u ON u.user_id = cp.user_id
            WHERE gc.group_id IN (
                SELECT group_id FROM group_members WHERE user_id = %s
            )
            ORDER BY gc.created_at DESC;
        """
        cursor.execute(query, (user_id,))
        rows = cursor.fetchall()

        grouped = {}
        for row in rows:
            consumption_id = row["consumption_id"]
            if consumption_id not in grouped:
                grouped[consumption_id] = {
                    "consumption_id": consumption_id,
                    "group_id": row["group_id"],
                    "group_name": row["group_name"],
                    "name": row["name"],
                    "amount": float(row["amount"]),
                    "created_at": row["created_at"],
                    "participants": [],
                }

            grouped[consumption_id]["participants"].append(
                {
                    "user_id": row["user_id"],
                    "user_name": row["user_name"],
                    "shared_amount": float(row["shared_amount"]),
                    "is_payer": row["is_payer"],
                    "status": row["status"],
                }
            )

        return list(grouped.values())
    finally:
        cursor.close()

@router.post("/expenses/create", status_code=status.HTTP_201_CREATED)
def add_expense(expense: ExpenseCreate, conn=Depends(get_db_connection)):
    cursor = conn.cursor()
    try:
        # 1. 紀錄總消費
        cursor.execute(
            "INSERT INTO group_consumptions (group_id, name, amount, type_id) VALUES (%s, %s, %s, %s) RETURNING consumption_id;",
            (expense.group_id, expense.name, expense.amount, expense.type_id)
        )
        consumption_id = cursor.fetchone()['consumption_id']

        # 2. 寫入參與者分帳明細
        for detail in expense.split_details:
            is_payer = (detail.user_id == expense.payer_id)
            cursor.execute(
                """
                INSERT INTO consumption_participants
                (consumption_id, user_id, is_payer, shared_amount)
                VALUES (%s, %s, %s, %s);
                """,
                (consumption_id, detail.user_id, is_payer, detail.shared_amount)
            )

        # 3. 同步到每個人的 personal_consumptions
        _sync_personal_consumptions(cursor, expense, consumption_id)
        
        conn.commit()
        return {"status": "success", "message": "分帳紀錄已新增"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"新增分帳失敗: {e}")
    finally:
        cursor.close()

@router.delete("/expenses/{consumption_id}", status_code=status.HTTP_200_OK)
def delete_expense(consumption_id: int, conn=Depends(get_db_connection)):
    """刪除群組消費紀錄"""
    cursor = conn.cursor()
    try:
        cursor.execute(
            "DELETE FROM personal_consumptions WHERE group_consumption_id = %s;",
            (consumption_id,)
        )
        # 先刪除參與者記錄
        cursor.execute(
            "DELETE FROM consumption_participants WHERE consumption_id = %s;",
            (consumption_id,)
        )
        # 再刪除消費記錄
        cursor.execute(
            "DELETE FROM group_consumptions WHERE consumption_id = %s;",
            (consumption_id,)
        )
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="找不到該消費紀錄")
        conn.commit()
        return {"status": "success", "message": "已刪除消費紀錄"}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"刪除消費紀錄失敗: {e}")
    finally:
        cursor.close()

@router.put("/expenses/{consumption_id}", status_code=status.HTTP_200_OK)
def update_expense(consumption_id: int, expense: ExpenseCreate, conn=Depends(get_db_connection)):
    """更新群組消費紀錄"""
    cursor = conn.cursor()
    try:
        # 更新消費記錄
        cursor.execute(
            """
            UPDATE group_consumptions
            SET group_id = %s, name = %s, amount = %s, type_id = %s
            WHERE consumption_id = %s;
            """,
            (expense.group_id, expense.name, expense.amount, expense.type_id, consumption_id)
        )
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="找不到該消費紀錄")

        # 刪除舊的參與者記錄，personal mirror 會在 helper 中一併重建
        cursor.execute(
            "DELETE FROM consumption_participants WHERE consumption_id = %s;",
            (consumption_id,)
        )

        # 重新插入參與者記錄
        for detail in expense.split_details:
            is_payer = (detail.user_id == expense.payer_id)
            cursor.execute(
                """
                INSERT INTO consumption_participants
                (consumption_id, user_id, is_payer, shared_amount)
                VALUES (%s, %s, %s, %s);
                """,
                (consumption_id, detail.user_id, is_payer, detail.shared_amount)
            )

        # 重建同步的 personal_consumptions
        _sync_personal_consumptions(cursor, expense, consumption_id)

        conn.commit()
        return {"status": "success", "message": "已更新消費紀錄"}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"更新消費紀錄失敗: {e}")
    finally:
        cursor.close()

@router.get("/settle/{group_id}")
def settle_group_expenses(group_id: int, conn=Depends(get_db_connection)):
    """一鍵結算：核心演算法，算出最終誰該轉帳給誰"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # Step 1: 透過關聯查詢，算出每個人的淨額 (Net Balance)
        # 淨額 = (代墊的總額) - (自己該付的總額)
        # 若 > 0，代表別人欠他錢；若 < 0，代表他欠別人錢
        # 只考慮 status = 'pending' 的參與者
        sql_query = """
            WITH UserPaid AS (
                SELECT cp.user_id, SUM(cp.shared_amount) as total_paid
                FROM consumption_participants cp
                JOIN group_consumptions gc ON cp.consumption_id = gc.consumption_id
                WHERE gc.group_id = %s
                  AND cp.is_payer = true
                  AND EXISTS (
                      SELECT 1 FROM consumption_participants cp2
                      WHERE cp2.consumption_id = cp.consumption_id
                        AND cp2.status = 'pending'
                        AND cp2.is_payer = false
                  )
                GROUP BY cp.user_id
            ),
            UserOwed AS (
                SELECT cp.user_id, SUM(cp.shared_amount) as total_owed
                FROM consumption_participants cp
                JOIN group_consumptions gc ON cp.consumption_id = gc.consumption_id
                WHERE gc.group_id = %s
                  AND cp.status = 'pending'
                  AND cp.is_payer = false
                GROUP BY cp.user_id
            )
            SELECT u.user_id, u.name,
                   COALESCE(p.total_paid, 0) - COALESCE(o.total_owed, 0) AS net_balance
            FROM group_members gm
            JOIN users u ON gm.user_id = u.user_id
            LEFT JOIN UserPaid p ON u.user_id = p.user_id
            LEFT JOIN UserOwed o ON u.user_id = o.user_id
            WHERE gm.group_id = %s;
        """
        cursor.execute(sql_query, (group_id, group_id, group_id))
        balances = cursor.fetchall()

        # Step 2: 把人分為「欠錢的 (Debtors)」與「等收錢的 (Creditors)」
        debtors = [{"user_id": b["user_id"], "name": b["name"], "amount": -float(b["net_balance"])} for b in balances if b["net_balance"] < -0.01]
        creditors = [{"user_id": b["user_id"], "name": b["name"], "amount": float(b["net_balance"])} for b in balances if b["net_balance"] > 0.01]

        transactions = []

        # Step 3: 雙指針/貪婪演算法進行配對結算
        i, j = 0, 0
        while i < len(debtors) and j < len(creditors):
            debtor = debtors[i]
            creditor = creditors[j]

            # 取兩人欠款與應收的最小值進行轉帳
            settle_amount = min(debtor["amount"], creditor["amount"])
            
            # 紀錄這筆轉帳
            transactions.append({
                "from_user_id": debtor["user_id"],
                "from_name": debtor["name"],
                "to_user_id": creditor["user_id"],
                "to_name": creditor["name"],
                "amount": round(settle_amount, 2)
            })

            # 扣除已結算金額
            debtors[i]["amount"] -= settle_amount
            creditors[j]["amount"] -= settle_amount

            # 如果這個人還清了，換下一個欠錢的人；如果這個人收齊了，換下一個收錢的人
            if debtors[i]["amount"] < 0.01:
                i += 1
            if creditors[j]["amount"] < 0.01:
                j += 1

        return {"group_id": group_id, "settlements": transactions}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"結算計算失敗: {e}")
    finally:
        cursor.close()