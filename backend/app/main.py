# 檔案：backend/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import goals, auth, ledger, stats, splits

app = FastAPI(title="GoalDigger API")

# Allow the Flutter web dev server (served from localhost on a random port)
# to call the API from the browser.
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["*"],
    allow_headers=["*"],
)
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
