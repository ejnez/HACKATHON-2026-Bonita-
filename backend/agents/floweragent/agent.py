from google.adk.agents.llm_agent import Agent
from .flowerPrompt import FLOWER_PROMPT
root_agent = Agent(
    model='gemini-2.5-flash',
    name='root_agent',
    description='A helpful assistant for based on the task you decide which flower to give to the user.',
    instruction=FLOWER_PROMPT,
)
