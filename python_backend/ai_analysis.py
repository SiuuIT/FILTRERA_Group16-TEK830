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
        "You are an IKEA workplace safety analyst. "
        "Below are short text records describing where an incident occurred and what happened. "
        "Each entry follows the format 'Location: ... — Incident: ...'.\n\n"
        "Your task is to analyze these reports and write a concise, insightful summary that identifies:\n"
        "1. The most common types of safety issues or hazards mentioned.\n"
        "2. The areas or locations where problems seem to happen most often.\n"
        "3. Likely root causes behind these incidents.\n"
        "4. Specific, practical actions IKEA could take to reduce risk in the future.\n\n"
        "Do not list each incident individually or give raw data. "
        "Instead, summarize patterns and trends you can infer from the text.\n\n"
        "Here are the reports:\n"
        f"{combined}\n\n"
        "Now provide your findings in 2–3 short paragraphs suitable for a safety meeting summary. "
        "Be professional, clear, and concise."
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
