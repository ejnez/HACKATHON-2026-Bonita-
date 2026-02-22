from google.adk.agents.llm_agent import Agent
from .prompt_priority import PRIORITIZER_PROMPT
from .predicttime import load_or_create

_time_model = load_or_create()

VALID_CATEGORIES = {"Personal Errands", "Health and Fitness", "Social", "Learning", "House Chore", "School Work", "Work Related", "Other"}

def predict_task_time(
    category: str,    # must be one of VALID_CATEGORIES
    hour_of_day: int, # 0-23
    day_of_week: int, # 0=Monday, 6=Sunday
    estimated_subtasks: int = 1,
    is_vague: bool = False,
    has_dependencies: bool = False,
) -> dict:
    """
    Predict estimated minutes for a single task.

    Call this when estimated_time is missing from a task.

    Args:
        category: Task category. Must be one of: Personal Errands, 
                  Health and Fitness, Social, Learning, House Chore, 
                  School Work, Work Related, Other
        hour_of_day: Hour when task is being planned (0-23)
        day_of_week: Day of week (0=Monday, 6=Sunday)
        estimated_subtasks: Number of subtasks implied (default 1)
        is_vague: Whether the task description was vague (default False)
        has_dependencies: Whether task depends on something else (default False)

    Returns:
        dict with predicted_minutes and confidence_score.
        If predicted_minutes is None, ask the user for their estimate.
    """
    if category not in VALID_CATEGORIES:
        category = "Other"

    features = {
        "category": category,
        "hour_of_day": hour_of_day,
        "day_of_week": day_of_week,
        "estimated_subtasks": estimated_subtasks,
        "is_vague": is_vague,
        "has_dependencies": has_dependencies,
    }
    return _time_model.predict(features)


root_agent = Agent(
    model='gemini-2.5-flash',
    name='root_agent',
    description='A helpful assistant for making a list of tasks from a brain dump.',
    instruction=PRIORITIZER_PROMPT,
    tools=[predict_task_time]
)
