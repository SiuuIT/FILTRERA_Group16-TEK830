import os
from openai import OpenAI
import asyncio

def analyze_descriptions(descriptions: list[str]) -> str:
    """Analyze and summarize incident descriptions using OpenAI (thread-safe for FastAPI)."""
    if not descriptions:
        return "No descriptions available for analysis."

    combined = "\n".join(descriptions[:100])

    prompt = (
        "You are a workplace safety expert. Below are several descriptions of accidents and incidents "
        "from an IKEA factory. Summarize the most common causes and propose actionable improvements "
        "to make the workplace safer.\n\n"
        f"{combined}\n\n"
        "Provide your answer as a short paragraph."
    )

    async def _call_openai():
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        response = await asyncio.to_thread(
            client.chat.completions.create,
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.5,
        )
        return response.choices[0].message.content.strip()

    try:
        # Run safely even if called from a sync FastAPI route
        return asyncio.run(_call_openai())
    except Exception as e:
        return f"AI analysis failed: {e}"



def analyze_location_and_description(descriptions: list[str]) -> str:
    """Analyze and summarize incident descriptions using OpenAI (thread-safe for FastAPI)."""
    if not descriptions:
        return "No descriptions available for analysis."

    combined = "\n".join(descriptions[:100])

    prompt = (
        "You are an IKEA workplace safety analyst. Below is a list of short incident reports. "
        "Each line includes the location and what happened, using this format:\n"
        "'Location: [area] — Incident: [description]'.\n\n"
        "Your task is to carefully read all reports and group them by location. "
        "For each location, identify the **most common or serious type of problem** mentioned there.\n\n"
        "Provide your answer as a clean, concise list like this:\n\n"
        "Location: Glue Kitchen — Main issue: Exposed wiring and unsafe electrical setups\n"
        "Location: Press Area — Main issue: Outdated fire signage and poor labeling\n"
        "Location: Foiling Line — Main issue: Unsafe chemical handling\n\n"
        "Do not repeat identical locations more than once. "
        "If multiple issues appear equally often, choose the one that seems most impactful.\n\n"
        "Here are the reports:\n"
        f"{combined}\n\n"
        "Now provide your analysis as a clear list, one location per line."
    )
    

    async def _call_openai():
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        response = await asyncio.to_thread(
            client.chat.completions.create,
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.5,
        )
        return response.choices[0].message.content.strip()

    try:
        # Run safely even if called from a sync FastAPI route
        return asyncio.run(_call_openai())
    except Exception as e:
        return f"AI analysis failed: {e}"
