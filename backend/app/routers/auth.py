
from fastapi import APIRouter, Depends, HTTPException
from psycopg2.extras import RealDictCursor
import bcrypt # 💡 這裡改用直接匯入 bcrypt
from schemas import UserCreate, UserLogin, UserResponse, TokenUpdate 
from database import get_db_connection

# 建立密碼加密工具 (使用 bcrypt 演算法)

# 建立會員部 Router
router = APIRouter(prefix="/auth", tags=["會員管理"])

# 1️ 註冊 API
@router.post("/register", response_model=dict)
def register_user(user_data: UserCreate, conn = Depends(get_db_connection)):
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # 強制截斷密碼到 72 字元
        safe_password = user_data.password[:72]
        
        # 💡 使用 bcrypt 直接進行加密
        # 注意：bcrypt 需要 bytes 格式，所以要用 .encode('utf-8')
        hashed_bytes = bcrypt.hashpw(safe_password.encode('utf-8'), bcrypt.gensalt())
        hashed_password = hashed_bytes.decode('utf-8') # 轉回字串存進資料庫
        
        sql_query = """
            INSERT INTO users (name, email, password)
            VALUES (%s, %s, %s)
            RETURNING user_id, name, email, created_at;
        """
        cursor.execute(sql_query, (user_data.name, user_data.email, hashed_password))
        new_user = cursor.fetchone()
        conn.commit()
        return {"status": "success", "message": "註冊成功！", "data": new_user}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=f"註冊失敗：{str(e)}")
    finally:
        cursor.close()


# 2️ 登入 API
@router.post("/login")
def login_user(user_data: UserLogin, conn = Depends(get_db_connection)):
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cursor.execute("SELECT * FROM users WHERE email = %s;", (user_data.email,))
        user = cursor.fetchone()

        if not user:
            raise HTTPException(status_code=401, detail="信箱或密碼錯誤")

        # 💡 使用 bcrypt 直接驗證密碼
        # user["password"] 是從資料庫取出的雜湊值，也要轉成 bytes
        is_valid = bcrypt.checkpw(user_data.password.encode('utf-8'), user["password"].encode('utf-8'))
        
        if not is_valid:
            raise HTTPException(status_code=401, detail="信箱或密碼錯誤")

        user_dict = dict(user)
        user_dict.pop("password", None)
        return {"status": "success", "message": f"歡迎回來，{user_dict['name']}！", "data": user_dict}
    finally:
        cursor.close()


# 3️ 更新推播金鑰 (FCM Token) API
@router.put("/fcm-token")
def update_fcm_token(token_data: TokenUpdate, conn = Depends(get_db_connection)):
    cursor = conn.cursor()
    try:
        # 更新該使用者的 fcm_token
        sql_query = """
            UPDATE users 
            SET fcm_token = %s 
            WHERE user_id = %s;
        """
        cursor.execute(sql_query, (token_data.fcm_token, token_data.user_id))
        conn.commit()

        # 如果 rowcount 是 0，代表資料庫裡沒有這個 user_id
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="找不到此使用者")

        return {"status": "success", "message": "手機推播金鑰綁定成功！"}
        
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=f"金鑰綁定失敗：{str(e)}")
    finally:
        cursor.close()
