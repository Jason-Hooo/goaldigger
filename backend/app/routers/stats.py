"""Stats endpoints."""

from collections import defaultdict

from fastapi import APIRouter, Depends

from ..database import get_data_client, unwrap_response
from ..schemas.auth import AuthUser
from ..schemas.stats import CategoryTotal, StatsSummary
from .auth import get_current_user

router = APIRouter(prefix="/stats", tags=["stats"])

LEDGER_TABLE = "ledger_entries"


@router.get("/summary", response_model=StatsSummary)
def get_summary(current_user: AuthUser = Depends(get_current_user)) -> StatsSummary:
    """Return aggregated ledger statistics for the current user."""

    client = get_data_client()
    response = (
        client.table(LEDGER_TABLE)
        .select("amount,type,category")
        .eq("user_id", current_user.id)
        .execute()
    )
    entries = unwrap_response(response, "Failed to fetch stats") or []

    income_total = 0.0
    expense_total = 0.0
    category_totals: dict[str, float] = defaultdict(float)

    for entry in entries:
        amount = float(entry.get("amount", 0))
        entry_type = entry.get("type")
        if entry_type == "income":
            income_total += amount
        elif entry_type == "expense":
            expense_total += amount
            category = entry.get("category") or "Other"
            category_totals[category] += amount

    top_categories = [
        CategoryTotal(category=key, total=value)
        for key, value in sorted(category_totals.items(), key=lambda item: item[1], reverse=True)
    ][:5]

    return StatsSummary(
        income_total=income_total,
        expense_total=expense_total,
        net_total=income_total - expense_total,
        entries_count=len(entries),
        top_categories=top_categories,
    )
