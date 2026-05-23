from fastapi import APIRouter, HTTPException, status
from typing import List
from database import get_db_connection
from schemas import GoalCreate, GoalResponse
from pydantic import BaseModel  # 💡 2. 補上這個 import
from datetime import datetime     # 💡 3. 補上這個 import

# 🚀 4. 直接把這個 Class 實體寫在 goals.py 裡！讓它在自己家讀取
class GoalAchieveResponse(BaseModel):
    goal_id: int
    completion_date: datetime

router = APIRouter(prefix="/goals", tags=["目標管理"])


@router.post("/", response_model=GoalResponse, status_code=status.HTTP_201_CREATED)
def create_goal(goal: GoalCreate):
    """新增願望目標：限制使用者同時只能有一個未達成目標。"""
    
    conn = next(get_db_connection())
    cursor = conn.cursor()

    try:
        # 檢查是否已有未達成目標
        check_query = """
            SELECT g.goal_id
            FROM goals g
            LEFT JOIN achievements a
            ON g.goal_id = a.goal_id
            WHERE g.user_id = %s
              AND a.goal_id IS NULL;
        """

        cursor.execute(check_query, (goal.user_id,))
        active_goal = cursor.fetchone()

        if active_goal:
            raise HTTPException(
                status_code=400,
                detail="請先完成目前的目標，再建立新的目標"
            )

        # 新增目標
        insert_query = """
            INSERT INTO goals
                (
                    user_id,
                    goal_name,
                    description,
                    target_amount,
                    deadline,
                    image_path
                )
            VALUES
                (%s, %s, %s, %s, %s, %s)
            RETURNING
                goal_id,
                user_id,
                goal_name,
                description,
                target_amount,
                cumulative_amount,
                deadline,
                image_path;
        """

        cursor.execute(
            insert_query,
            (
                goal.user_id,
                goal.goal_name,
                goal.description,
                goal.target_amount,
                goal.deadline,
                goal.image_path,
            ),
        )

        new_goal = cursor.fetchone()

        conn.commit()

        return new_goal

    except HTTPException:
        raise

    except Exception as e:
        conn.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"新增目標失敗：{e}"
        )

    finally:
        cursor.close()
        conn.close()


@router.get("/detail/{goal_id}", response_model=GoalResponse)
def get_goal_detail(goal_id: int):
    """查看單一目標詳細資料。"""

    conn = next(get_db_connection())
    cursor = conn.cursor()

    try:
        cursor.execute(
            """
            SELECT
                goal_id,
                user_id,
                goal_name,
                description,
                target_amount,
                cumulative_amount,
                deadline,
                image_path
            FROM goals
            WHERE goal_id = %s;
            """,
            (goal_id,),
        )

        goal = cursor.fetchone()

        if not goal:
            raise HTTPException(
                status_code=404,
                detail="找不到該目標"
            )

        return goal

    finally:
        cursor.close()
        conn.close()


@router.post(
    "/achieve/{goal_id}",
    response_model=GoalAchieveResponse,
    status_code=status.HTTP_200_OK
)
def achieve_goal(goal_id: int):
    """達成目標：將已達標的目標寫入 achievements 表。"""

    conn = next(get_db_connection())
    cursor = conn.cursor()

    try:
        # 檢查目標是否存在
        cursor.execute(
            """
            SELECT
                goal_id,
                target_amount,
                cumulative_amount
            FROM goals
            WHERE goal_id = %s;
            """,
            (goal_id,),
        )

        goal = cursor.fetchone()

        if not goal:
            raise HTTPException(
                status_code=404,
                detail="目標不存在"
            )

        # 檢查是否已達標
        if goal["cumulative_amount"] < goal["target_amount"]:
            raise HTTPException(
                status_code=400,
                detail="存錢進度尚未達標，還不能解鎖成就喔！"
            )

        # 寫入 achievements
        cursor.execute(
            """
            INSERT INTO achievements (goal_id, completion_date)
            VALUES (%s, CURRENT_TIMESTAMP)
            ON CONFLICT (goal_id) DO NOTHING
            RETURNING goal_id, completion_date;
            """,
            (goal_id,),
        )

        achieve_data = cursor.fetchone()

        # 如果之前已經達成過
        if not achieve_data:
            cursor.execute(
                """
                SELECT
                    goal_id,
                    completion_date
                FROM achievements
                WHERE goal_id = %s;
                """,
                (goal_id,),
            )

            achieve_data = cursor.fetchone()

        conn.commit()

        return {
            "goal_id": achieve_data["goal_id"],
            "completion_date": achieve_data["completion_date"]
        }

    except HTTPException:
        raise

    except Exception as e:
        conn.rollback()

        raise HTTPException(
            status_code=500,
            detail=f"達成目標失敗：{e}"
        )

    finally:
        cursor.close()
        conn.close()


@router.get("/{user_id}", response_model=List[GoalResponse])
def get_user_goals(user_id: int):
    """取得該使用者的所有願望清單。"""

    conn = next(get_db_connection())
    cursor = conn.cursor()

    try:
        cursor.execute(
            """
            SELECT
                goal_id,
                user_id,
                goal_name,
                description,
                target_amount,
                cumulative_amount,
                deadline,
                image_path
            FROM goals
            WHERE user_id = %s
            ORDER BY goal_id DESC;
            """,
            (user_id,),
        )

        goals = cursor.fetchall()

        return goals

    finally:
        cursor.close()
        conn.close()