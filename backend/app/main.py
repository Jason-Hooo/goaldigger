# 檔案：backend/app/main.py
import firebase_admin
from firebase_admin import credentials
from fastapi import FastAPI
from apscheduler.schedulers.background import BackgroundScheduler
from scheduler import check_inactive_users, allocate_daily_budget, reward_daily_savings 
from routers import goals, auth, ledger, stats, splits, finance  

app = FastAPI(title="GoalDigger API")

try:
    cred = credentials.Certificate("../firebase-adminsdk.json") 
    firebase_admin.initialize_app(cred)
except Exception as e:
   print(f"Firebase 初始化失敗 : {e}")
# 掛載部門 Router
app.include_router(auth.router) 
app.include_router(goals.router)  
app.include_router(ledger.router)
app.include_router(stats.router)
app.include_router(splits.router)
app.include_router(finance.router) 

scheduler = BackgroundScheduler()

@app.on_event("startup")
def start_scheduler():
    # 排程 1：每日早上 9:00 檢查三天未記帳的客戶並推播 [cite: 14]
    scheduler.add_job(check_inactive_users, 'cron', hour=17, minute=33)
    
    # 排程 2：【方案 B 核心】每日凌晨 00:00 自動將花費標準加進目標進度條中 
    scheduler.add_job(allocate_daily_budget, 'cron', hour=0, minute=0)
    
    scheduler.start()

@app.on_event("shutdown")
def stop_scheduler():
    scheduler.shutdown()

@app.get("/")
def read_root():
    return {
        "project": "GoalDigger",
        "version": "1.0.0",
        "status": "Running",
        "developer": "DBNS project Team"
    }
    
@app.get("/debug/trigger-reward", tags=["開發測試專用"])
def debug_trigger_reward():
    """手動觸發每日結算獎勵機制 (測試用)"""
    reward_daily_savings()
    return {"status": "success", "message": "獎勵結算函數已手動執行，請去資料庫檢查目標金額！"}
