"""Main FastAPI application."""

from fastapi import FastAPI

from .routers import auth, goals, ledger, splits, stats

app = FastAPI(title="GoalDigger API")

app.include_router(auth.router)
app.include_router(ledger.router)
app.include_router(goals.router)
app.include_router(splits.router)
app.include_router(stats.router)


@app.get("/")
def read_root() -> dict:
    """Root endpoint for GoalDigger API."""

    return {"message": "Welcome to GoalDigger API"}


@app.get("/health")
def health_check() -> dict:
    """Return a basic health status for the API."""

    return {"status": "ok"}
