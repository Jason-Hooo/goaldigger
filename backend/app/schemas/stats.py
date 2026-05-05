"""Stats schemas."""

from pydantic import BaseModel


class CategoryTotal(BaseModel):
    """Total amount per category."""

    category: str
    total: float


class StatsSummary(BaseModel):
    """Summary stats response."""

    income_total: float
    expense_total: float
    net_total: float
    entries_count: int
    top_categories: list[CategoryTotal]
