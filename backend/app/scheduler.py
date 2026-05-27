from database import get_db_connection
from database import get_raw_db_connection
from psycopg2.extras import RealDictCursor
from datetime import datetime
from firebase_admin import messaging  

def check_inactive_users():
    print(f"[{datetime.now()}] 開始檢查兩日未記帳的客戶")
    conn = get_raw_db_connection() # 💡 修改這裡
    cursor = conn.cursor()
    try:
        sql_query = """
            SELECT u.user_id, u.name, u.fcm_token, MAX(p.created_at) as last_record
            FROM users u
            LEFT JOIN personal_consumptions p ON u.user_id = p.user_id
            WHERE u.fcm_token IS NOT NULL
            GROUP BY u.user_id, u.name, u.fcm_token
            HAVING MAX(p.created_at) < NOW() - INTERVAL '2 days' 
               OR MAX(p.created_at) IS NULL;
        """
        cursor.execute(sql_query)
        inactive_users = cursor.fetchall()
        
        if not inactive_users:
            print(f"[{datetime.now()}] 檢查完畢：目前所有用戶都很乖，沒有人需要被推播提醒！")
            return

        print(f"[{datetime.now()}] 發現 {len(inactive_users)} 位需要提醒的用戶，準備發送推播...")
        
        
        for user in inactive_users:
            token = user['fcm_token']
            message = messaging.Message(
                notification=messaging.Notification(
                    title="GoalDigger 溫馨提醒 💰",
                    body=f"嗨 {user['name']}，你已經超過兩天沒記帳囉！離目標又遠了一步嗎？快來記錄一下吧！",
                ),
                token=token,
            )
            response = messaging.send(message)
            print(f"成功發送推播給 {user['name']} (Message ID: {response})")
    except Exception as e:
        print(f"推播失敗：{e}")
    finally:
        cursor.close()
        conn.close() 

def allocate_daily_budget():
    """【方案 B 核心】每日凌晨自動將當日的可支配所得（花費標準）存入活躍目標中"""
    print(f"[{datetime.now()}] 開始自動發放今日可支配所得至活躍目標條...")
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        sql_query = """
            UPDATE goals g
            SET cumulative_amount = g.cumulative_amount + m.daily_usable_amount
            FROM monthly_financial_info m
            LEFT JOIN achievements a ON g.goal_id = a.goal_id
            WHERE g.user_id = m.user_id 
              AND a.goal_id IS NULL
              AND m.record_month = TO_CHAR(CURRENT_DATE, 'YYYY-MM');
        """
        cursor.execute(sql_query)
        conn.commit()
        print(f"[{datetime.now()}] 每日花費標準已成功同步至所有活躍目標進度條！")
    except Exception as e:
        conn.rollback()
        print(f"每日預算發放失敗：{e}")
    finally:
        cursor.close()
        # conn.close()
        
# ==========================================
# 3. 每日結算：省下的錢轉為目標進度
# ==========================================
def reward_daily_savings():
    """每日結算：若今日支出 < 每日預算，將差額獎勵至目標進度中"""
    print(f"[{datetime.now()}] 啟動每日結算儲蓄獎勵機制...")
    conn = get_raw_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # SQL 核心邏輯：
        # 1. 算出今日所有使用者省下的錢 (每日額度 - 今日消費總和)
        # 2. 只針對有剩餘預算 (預算 > 花費) 的人，把差額加進目標中
        sql_query = """
            UPDATE goals g
            SET cumulative_amount = g.cumulative_amount + (m.daily_usable_amount - COALESCE(daily_expenses.total, 0))
            FROM monthly_financial_info m
            LEFT JOIN (
                SELECT user_id, SUM(amount) as total
                FROM personal_consumptions
                WHERE created_at::date = CURRENT_DATE
                GROUP BY user_id
            ) daily_expenses ON m.user_id = daily_expenses.user_id
            WHERE g.user_id = m.user_id
              AND m.record_month = TO_CHAR(CURRENT_DATE, 'YYYY-MM')
              AND m.daily_usable_amount > COALESCE(daily_expenses.total, 0);
        """
        cursor.execute(sql_query)
        conn.commit()
        print(f"[{datetime.now()}] 今日結算完成！省下的預算已自動存入目標。")
        
    except Exception as e:
        conn.rollback()
        print(f"結算獎勵執行失敗：{e}")
        
    finally:
        cursor.close()
        conn.close()
        
     
