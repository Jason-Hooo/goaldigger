from pydantic import BaseModel, Field, EmailStr
from typing import Optional
from datetime import date, datetime
from typing import List, Dict

class UserCreate(BaseModel):
    name: str = Field(..., example="王小明")
    email: EmailStr = Field(..., example="ming@nccu.edu.tw") # EmailStr 會自動檢查信箱格式有沒有 @
    password: str = Field(..., min_length=6, example="password123") # 密碼至少 6 碼

# 登入表單
class UserLogin(BaseModel):
    email: EmailStr = Field(..., example="ming@nccu.edu.tw")
    password: str = Field(...)

# 回傳給前端的會員資料 (不可以包含密碼)
class UserResponse(BaseModel):
    user_id: int
    name: str
    email: str
    created_at: datetime
    
    class Config:
        from_attributes = True


#  這是前端 (Flutter) 傳來「新增目標」時，必須符合的格式
class GoalCreate(BaseModel):
    user_id: int = Field(..., description="誰的目標 (請先確保 users 表裡有這個人)")
    goal_name: str = Field(..., example="買一台 PS5")
    target_amount: float = Field(..., gt=0, example=15000.0, description="目標金額必須大於 0")
    
    # Optional 代表選填 (前端不傳也沒關係，會自動變成 None)
    description: Optional[str] = None
    deadline: Optional[date] = None
    image_path: Optional[str] = None
    

# 這是後端要把「完整的目標資料」回傳給前端時的格式
class GoalResponse(BaseModel):
    goal_id: int
    user_id: int
    goal_name: str
    description: Optional[str] = None
    target_amount: float
    cumulative_amount: float
    deadline: Optional[date] = None
    image_path: Optional[str] = None
    completion_date: Optional[datetime] = None

    class Config:
        from_attributes = True  # 讓 Pydantic 可以順利讀取資料庫撈出來的資料
        
class ExpenseSummary(BaseModel):
    category: str
    total_amount: float

class LedgerCreate(BaseModel):
    user_id: int
    type_id: int
    amount: float = Field(..., gt=0)
    description: Optional[str] = None
    goal_id: Optional[int] = None


class LedgerUpdate(BaseModel):
    user_id: int
    type_id: int
    amount: float = Field(..., gt=0)
    description: Optional[str] = None
    goal_id: Optional[int] = None


class ExpenseTypeCreate(BaseModel):
    user_id: int
    type_name: str = Field(..., min_length=1, max_length=40)
    is_expense: bool = True


class ExpenseTypeUpdate(BaseModel):
    user_id: int
    type_name: str = Field(..., min_length=1, max_length=40)
    is_expense: bool


class LedgerResponse(BaseModel):
    consumption_id: int
    user_id: int
    type_id: int
    amount: float
    description: Optional[str] = None  
    created_at: datetime
    goal_id: Optional[int] = None
    type_name: Optional[str] = None
    is_expense: Optional[bool] = None

    class Config:
        from_attributes = True  # 


class GoalAchieveResponse(BaseModel):
    goal_id: int
    completion_date: datetime

class GroupCreate(BaseModel):
    group_name: str
    user_ids: List[int]  # 參與此群組的使用者 ID 列表

class GroupMemberAdd(BaseModel):
    user_ids: List[int]

class SplitDetail(BaseModel):
    user_id: int
    shared_amount: float

class ExpenseCreate(BaseModel):
    group_id: int
    name: str
    amount: float
    payer_id: int  # 誰先代墊的
    type_id: Optional[int] = None  # 支出類別
    split_details: List[SplitDetail]  # 大家平分的明細
    

class GoalUpdate(BaseModel):
    goal_name: Optional[str] = None
    description: Optional[str] = None
    target_amount: Optional[float] = Field(None, gt=0)
    deadline: Optional[date] = None
    image_path: Optional[str] = None
    cumulative_amount: Optional[float] = Field(None, ge=0)
