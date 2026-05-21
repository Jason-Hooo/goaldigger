"""Stats endpoints."""

from collections import defaultdict
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends

from ..database import get_data_client, unwrap_response
from ..schemas.auth import AuthUser
from ..schemas.stats import CategoryTotal, DailyTrend, GoalProgress, StatsSummary
from .auth import get_current_user
from .goals import GOALS_TABLE

router = APIRouter(prefix="/stats", tags=["stats"])

LEDGER_TABLE = "ledger_entries"


def fetch_ledger_entries(user_id: str, start_date: Optional[str] = None):
    """撈取特定使用者的記帳紀錄，可透過 start_date 過濾減少資料量"""
    client = get_data_client()
    query = client.table(LEDGER_TABLE).select("amount,type,category,date").eq("user_id", user_id)
    
    if start_date:
        query = query.gte("date", start_date)
        
    response = query.execute()
    return unwrap_response(response, "Failed to fetch ledger entries") or []


@router.get("/summary", response_model=StatsSummary)
def get_summary(current_user: AuthUser = Depends(get_current_user)) -> StatsSummary:
    """Return aggregated ledger statistics, trends, and individual goals for the current user."""
    
    today = datetime.now()
    first_day_of_month = today.replace(day=1).strftime("%Y-%m-%d")
    seven_days_ago = (today - timedelta(days=7)).strftime("%Y-%m-%d")
    earliest_date = min(first_day_of_month, seven_days_ago)
    
    all_entries = fetch_ledger_entries(current_user.id, start_date=earliest_date)
    
    income_total = 0.0
    expense_total = 0.0
    monthly_entries_count = 0
    category_totals: dict[str, float] = defaultdict(float)
    daily_totals: dict[str, float] = defaultdict(float)
    
    for entry in all_entries:
        date_str = entry.get("date")
        if not date_str:
            continue
            
        amount = float(entry.get("amount", 0))
        entry_type = entry.get("type")
        category = entry.get("category") or "Other"
        
        # 1. 本月份資料計算
        if date_str >= first_day_of_month:
            monthly_entries_count += 1
            if entry_type == "income":
                income_total += amount
            elif entry_type == "expense":
                expense_total += amount
                category_totals[category] += amount
                
        # 2. 近 7 天趨勢計算
        if date_str >= seven_days_ago and entry_type == "expense":
            daily_totals[date_str] += amount

    client = get_data_client()
    goals_resp = (
        client.table(GOALS_TABLE)
        .select("title, target_amount, current_amount")
        .eq("user_id", current_user.id)
        .eq("status", "active")
        .execute()
    )
    goals_data = unwrap_response(goals_resp, "Failed to fetch goals") or []
    
    goals_progress = []
    for g in goals_data:
        title = g.get("title", "未命名目標")
        target = float(g.get("target_amount", 1.0))  # 預設 1 避免除以 0 錯誤
        current = float(g.get("current_amount", 0.0))
        
        # 計算進度比例並限制最大值為 1.0 (100%)
        progress_ratio = min(current / target if target > 0 else 0.0, 1.0)
        goals_progress.append(GoalProgress(title=title, progress=round(progress_ratio, 2)))

    # 先將分類依總額降序排序，取前五大
    sorted_cats = sorted(category_totals.items(), key=lambda item: item[1], reverse=True)[:5]
    
    top_categories = []
    for k, v in sorted_cats:
        ratio = (v / expense_total) if expense_total > 0 else 0.0
        top_categories.append(
            CategoryTotal(category=k, total=v, ratio=round(ratio, 4))
        )
    
    trend_stats = [
        DailyTrend(date=k, amount=v)
        for k, v in sorted(daily_totals.items(), key=lambda item: item[0])
    ]
    
    return StatsSummary(
        income_total=income_total,
        expense_total=expense_total,
        net_total=income_total - expense_total,
        entries_count=monthly_entries_count,
        top_categories=top_categories,
        trend_stats=trend_stats,
        goals_progress=goals_progress  
    )