# 檔案：backend/app/main.py
from fastapi import FastAPI
from apscheduler.schedulers.background import BackgroundScheduler
from .scheduler import allocate_daily_budget
from .routers import goals, auth, ledger, stats, splits

app = FastAPI(title="GoalDigger API")
# 掛載部門 Router
app.include_router(auth.router) 
app.include_router(goals.router)  
app.include_router(ledger.router)
app.include_router(stats.router)
app.include_router(splits.router) 

scheduler = BackgroundScheduler()

@app.on_event("startup")
def start_scheduler():
    # 排程 1：【方案 B 核心】每日凌晨 00:00 自動將花費標準加進目標進度條中
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
