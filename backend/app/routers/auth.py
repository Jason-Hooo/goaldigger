
from fastapi import APIRouter, Depends, HTTPException
from psycopg2.extras import RealDictCursor
from passlib.context import CryptContext
from schemas import UserCreate, UserLogin, UserResponse, TokenUpdate # 👈 幫你整併在一行了
from database import get_db_connection

# 建立密碼加密工具 (使用 bcrypt 演算法)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# 建立會員部 Router
router = APIRouter(prefix="/auth", tags=["會員管理"])

# 1️ 註冊 API
@router.post("/register", response_model=dict)
def register_user(user_data: UserCreate, conn = Depends(get_db_connection)):
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # 先把前端傳來的明碼密碼加密
        hashed_password = pwd_context.hash(user_data.password)
        
        # 寫入資料庫
        sql_query = """
            INSERT INTO users (name, email, password)
            VALUES (%s, %s, %s)
            RETURNING user_id, name, email, created_at;
        """
        cursor.execute(sql_query, (user_data.name, user_data.email, hashed_password))
        new_user = cursor.fetchone()
        conn.commit()

        return {
            "status": "success",
            "message": "註冊成功！",
            "data": new_user
        }

    except Exception as e:
        conn.rollback()
        # 如果信箱已經存在，PostgreSQL 會報錯 (設 UNIQUE)，會在這裡攔截
        if "unique constraint" in str(e).lower():
            raise HTTPException(status_code=400, detail="這個 Email 已經被註冊過囉！")
        raise HTTPException(status_code=400, detail=f"註冊失敗：{str(e)}")

    finally:
        cursor.close()


# 2️ 登入 API
@router.post("/login")
def login_user(user_data: UserLogin, conn = Depends(get_db_connection)):
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # 去資料庫找這個 email
        cursor.execute("SELECT * FROM users WHERE email = %s;", (user_data.email,))
        user = cursor.fetchone()

        # 檢查 1：找不到人
        if not user:
            raise HTTPException(status_code=401, detail="信箱或密碼錯誤")

        # 檢查 2：密碼比對
        if not pwd_context.verify(user_data.password, user["password"]):
            raise HTTPException(status_code=401, detail="信箱或密碼錯誤")

        # 登入成功，回傳資料 (把密碼從字典裡刪除再回傳，保護安全)
        del user["password"]
        return {
            "status": "success",
            "message": f"歡迎回來，{user['name']}！",
            "data": user
        }
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"登入過程發生錯誤：{str(e)}")
        
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