# 檔案：backend/app/main.py
from fastapi import FastAPI
from .routers import goals, auth, ledger, stats, splits

app = FastAPI(title="GoalDigger API")
# 掛載部門 Router
app.include_router(auth.router) 
app.include_router(goals.router)  
app.include_router(ledger.router)
app.include_router(stats.router)
app.include_router(splits.router) 

@app.get("/")
def read_root():
    return {
        "project": "GoalDigger",
        "version": "1.0.0",
        "status": "Running",
        "developer": "DBNS project Team"
    }
