# 檔案：backend/app/main.py
import firebase_admin
from firebase_admin import credentials
from fastapi import FastAPI
from routers import goals, auth, ledger, stats, splits 
from apscheduler.schedulers.background import BackgroundScheduler
from scheduler import check_inactive_users

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

scheduler = BackgroundScheduler()

@app.on_event("startup")
def start_scheduler():
    scheduler.add_job(check_inactive_users, 'cron', hour=9, minute=0)
    scheduler.start()
    

@app.on_event("shutdown")
def stop_scheduler():
    scheduler.shutdown()

@app.get("/")
def read_root():
    return {"project": "GoalDigger",
        "version": "1.0.0",
        "status": "Running",
        "developer": "DBNS project Team"}