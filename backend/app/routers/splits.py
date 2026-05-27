from fastapi import APIRouter, HTTPException, Depends, status
from typing import List, Dict
from pydantic import BaseModel
from database import get_db_connection
from psycopg2.extras import RealDictCursor
from schemas import GroupCreate, ExpenseCreate

router = APIRouter(prefix="/splits", tags=["分帳管理"])



@router.post("/groups/", status_code=status.HTTP_201_CREATED)
def create_group(group: GroupCreate, conn=Depends(get_db_connection)):
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # 1. 建立群組
        cursor.execute(
            "INSERT INTO groups_table (group_name) VALUES (%s) RETURNING group_id, group_name;",
            (group.group_name,)
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
            SELECT g.group_id, g.group_name, g.created_at
            FROM groups_table g
            JOIN group_members gm ON g.group_id = gm.group_id
            WHERE gm.user_id = %s
            ORDER BY g.created_at DESC;
        """
        cursor.execute(query, (user_id,))
        return cursor.fetchall()
    finally:
        cursor.close()

@router.post("/expenses/", status_code=status.HTTP_201_CREATED)
def add_expense(expense: ExpenseCreate, conn=Depends(get_db_connection)):
    cursor = conn.cursor()
    try:
        # 1. 紀錄總消費
        cursor.execute(
            "INSERT INTO group_consumptions (group_id, name, amount) VALUES (%s, %s, %s) RETURNING consumption_id;",
            (expense.group_id, expense.name, expense.amount)
        )
        consumption_id = cursor.fetchone()['consumption_id']
        personal_records = []

        # 2. 寫入參與者分帳明細
        for detail in expense.split_details:
            is_payer = (detail.user_id == expense.payer_id)
            # 簡化計算，這裡假設 sharing_ratio 先用 1 代替，實際金額依前端傳入為主
            cursor.execute(
                """
                INSERT INTO consumption_participants 
                (consumption_id, user_id, is_payer, sharing_ratio, shared_amount) 
                VALUES (%s, %s, %s, %s, %s);
                """,
                (consumption_id, detail.user_id, is_payer, 1, detail.shared_amount)
            )
            
            if detail.shared_amount > 0:
                personal_records.append((
                    detail.user_id, 
                    99,  # 預設的 type_id，代表「群組分帳」類別 (需確保資料庫裡有這個 type_id)
                    detail.shared_amount, 
                    f"{expense.name} (群組分帳)"
                ))
                
                cursor.execute("""
                    SELECT daily_usable_amount FROM monthly_financial_info 
                    WHERE user_id = %s AND record_month = TO_CHAR(CURRENT_DATE, 'YYYY-MM');
                """, (detail.user_id,))
                budget_row = cursor.fetchone()
                daily_limit = budget_row['daily_usable_amount'] if budget_row else 0

                # B. 取得該成員今日已花費總額 (不含這筆)
                cursor.execute("""
                    SELECT COALESCE(SUM(amount), 0) as total_spent FROM personal_consumptions 
                    WHERE user_id = %s AND created_at::date = CURRENT_DATE;
                """, (detail.user_id,))
                today_spent = cursor.fetchone()['total_spent']

                # C. 計算是否超支
                remaining_budget = float(daily_limit) - float(today_spent)
                if detail.shared_amount > remaining_budget:
                    # 算出超出了多少錢
                    excess_amount = float(detail.shared_amount) - max(0, remaining_budget)
                    
                    # D. 找出他的「活躍目標」並扣除進度 (使用 GREATEST 確保扣完最少是 0，不會變負債)
                    cursor.execute("""
                        UPDATE goals 
                        SET cumulative_amount = cumulative_amount - %s
                        WHERE user_id = %s 
                          AND goal_id NOT IN (SELECT goal_id FROM achievements)
                    """, (excess_amount, detail.user_id))
                    print(f"[系統日誌] 成員 {detail.user_id} 群組分帳超支！從活躍目標扣除了 {excess_amount} 元")

        # 3. 💡 批次將分帳結果同步到每個人的 personal_consumptions
        if personal_records:
            cursor.executemany(
                """
                INSERT INTO personal_consumptions 
                (user_id, type_id, amount, description, created_at)
                VALUES (%s, %s, %s, %s, NOW());
                """,
                personal_records
            )
        
        conn.commit()
        return {"status": "success", "message": "分帳紀錄已新增"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"新增分帳失敗: {e}")
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
        sql_query = """
            WITH UserPaid AS (
                SELECT cp.user_id, SUM(gc.amount) as total_paid
                FROM consumption_participants cp
                JOIN group_consumptions gc ON cp.consumption_id = gc.consumption_id
                WHERE gc.group_id = %s AND cp.is_payer = true
                GROUP BY cp.user_id
            ),
            UserOwed AS (
                SELECT cp.user_id, SUM(cp.shared_amount) as total_owed
                FROM consumption_participants cp
                JOIN group_consumptions gc ON cp.consumption_id = gc.consumption_id
                WHERE gc.group_id = %s
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
        debtors = [{"name": b["name"], "amount": -float(b["net_balance"])} for b in balances if b["net_balance"] < -0.01]
        creditors = [{"name": b["name"], "amount": float(b["net_balance"])} for b in balances if b["net_balance"] > 0.01]

        transactions = []

        # Step 3: 雙指針/貪婪演算法進行配對結算
        i, j = 0, 0
        while i < len(debtors) and j < len(creditors):
            debtor = debtors[i]
            creditor = creditors[j]

            # 取兩人欠款與應收的最小值進行轉帳
            settle_amount = min(debtor["amount"], creditor["amount"])
            
            # 紀錄這筆轉帳
            transactions.append(f"{debtor['name']} 給 {creditor['name']} {round(settle_amount, 2)} 元")

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