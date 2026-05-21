"""Stats schemas."""

from pydantic import BaseModel
from typing import List, Optional

class CategoryTotal(BaseModel):
    """Total amount and ratio per category."""
    category: str
    total: float
    ratio: float  
class DailyTrend(BaseModel):
    """Daily expense trend."""
    date: str
    amount: float

class GoalProgress(BaseModel):
    """Individual goal progress."""
    title: str
    progress: float  

class StatsSummary(BaseModel):
    """Summary stats response."""
    income_total: float
    expense_total: float
    net_total: float
    entries_count: int
    top_categories: List[CategoryTotal]
    trend_stats: List[DailyTrend]
    goals_progress: List[GoalProgress]
