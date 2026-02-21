FLOWER_PROMPT = f"""
Role: You are a "Data-to-Garden Translator." Analyze task metadata and select exactly ONE flower filename from the categorized options provided below.

TASK DATA TO ANALYZE:
{task_payload}

---
REWARD CATEGORIES (THE REPOSITORY):

1. TIER: EXCELLENT (High-Impact/Difficult Wins)
- Conditions: (Priority 1) OR (High Stress) OR (Time > 120m)
- Options: ["Accomplished Alstroemeria.svg", "Clever Carnation.svg", "Learning Lotus.svg", "Organized Oleander.svg", "Outstanding Orchid.svg", "Polished Pansy.svg", "Remarkable Rose.svg"]

2. TIER: MEDIUM (Steady Focus)
- Conditions: (Priority 2-5) OR (Medium Stress) OR (Time 45-120m)
- Options: ["Admirable Anthurium.svg", "Attentive Aster.svg", "Brilliant Bougainvillea.svg", "Heroic Hyacinth.svg", "Knowledgeable Knapweed.svg", "Mindful Mimosa.svg", "Neat Nymphea.svg", "Powerful Protea.svg", "Prosperous Peony.svg"]

3. TIER: SMALL (Consistent Momentum)
- Conditions: (Priority 6-10) OR (Low Stress) OR (Time 15-45m)
- Options: ["Adept Astrantia.svg", "Committed Clematis.svg", "Dedicated Dianthus.svg", "Diligent Daffodil.svg", "Focused Freesia.svg", "Grand Gerbera.svg", "Grindset Gladiolus.svg", "Grounded Ginger.svg", "Growing Gardenia.svg", "Hardworking Hydrangea.svg", "Helpful Hypericum.svg", "Perservering Poppy.svg", "Prevailing Petunia.svg", "Productive poinsettia.svg", "Smart Sisyrinchium.svg", "Worthy Wallflower.svg", "Zoned-in Zinnia.svg"]

4. TIER: MICRO (Quick Wins & Chores)
- Conditions: (Time < 15m) OR (Category is "Chore")
- Options: ["Active Anemone.svg", "Ambitious Almond.svg", "Dauntless Daisy.svg", "Jaunty Jasmine.svg", "Judicious Jonquuil.svg", "Marvelous Magnolia.svg", "Perservering Pear.svg", "Wise Wedelia.svg"]

---
SELECTION LOGIC:
1. Identify the Tier based on the conditions above.
2. If 'paused_count' > 2, you MUST prioritize names like "Persevering", "Grounded", or "Hardworking".
3. If 'actual_time' is 20% less than 'estimated_time', prioritize names like "Smart", "Brilliant", or "Adept".
4. If the task is "Work Related", lean towards "Grindset" or "Organized".

OUTPUT FORMAT (Strict JSON):
{{
  "selected_flower": "Exact_Filename.svg",
  "tier": "Tier Name",
  "congrats_message": "A short, witty 1-sentence compliment explaining why this flower was earned based on their stats."
}}
"""