from fastapi import FastAPI
from pydantic import BaseModel
from jose import jwt

app = FastAPI()

class LoginRequest(BaseModel):
    username: str
    password: str

# @app.get("/hello")
# def hello():
#     return {"message": "Hello from Python!"}

def create_token(username: str):
    data = {"username": username}  # 把使用者資訊包進去
    token = jwt.encode(data, "你的密鑰", algorithm="HS256")  # 加密
    return token

@app.post("/login")
def login(data: LoginRequest):

    #先假設username和password是固定的，實際應該從資料庫獲取
    if data.username == "test" and data.password == "1234":
        token = create_token(data.username)
        return {"status": "ok", "token": token}
    return {"status": "fail", "message": "Invalid credentials"}

# 啟動：uvicorn main:app --host 0.0.0.0 --port 8000