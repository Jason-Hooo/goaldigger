from database import get_db_connection
from psycopg2.extras import RealDictCursor
from datetime import datetime
from firebase_admin import messaging  # 引入 Firebase 寄信模組

def check_inactive_users():
    print(f"[{datetime.now()}] 開始檢查兩日未記帳的客戶")
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # 把 fcm_token 撈出來，而且只找 fcm_token 不為空的人
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
        
        for user in inactive_users:
            token = user['fcm_token']
            
            # 建立要推播的訊息內容
            message = messaging.Message(
                notification=messaging.Notification(
                    title="GoalDigger 溫馨提醒 💰",
                    body=f"嗨 {user['name']}，你已經超過兩天沒記帳囉！離目標又遠了一步嗎？快來記錄一下吧！",
                ),
                token=token, # 指定要寄給這台手機
            )
            
            # 傳送推播
            response = messaging.send(message)
            print(f"成功發送推播給 {user['name']} (Message ID: {response})")
            
    except Exception as e:
        print(f"推播失敗：{e}")
    finally:
        cursor.close()
        conn.close()