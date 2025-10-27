import os
from openai import OpenAI
import asyncio
import json

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
        "You are an IKEA workplace safety analyst. Below is a list of short incident reports, "
        "each with a location and what happened. Format:\n"
        "'Location: [area] — Incident: [description]'.\n\n"
        "Your task:\n"
        "1. Group incidents by location.\n"
        "2. For each location, identify the main recurring safety problem.\n"
        "3. Suggest one or two short, actionable steps that could be taken to reduce or prevent that problem.\n\n"
        "Return your response **strictly** as a valid JSON object where each key is the location name and each value "
        "is an object with two fields: 'problem' and 'actions'. Example:\n\n"
        "{\n"
        "  \"Glue Kitchen\": {\n"
        "    \"problem\": \"Unsafe electrical setups and damaged wiring\",\n"
        "    \"actions\": \"Inspect electrical systems weekly and replace worn cables\"\n"
        "  },\n"
        "  \"Press\": {\n"
        "    \"problem\": \"Outdated fire signage and unclear evacuation routes\",\n"
        "    \"actions\": \"Update signage and conduct quarterly fire drills\"\n"
        "  }\n"
        "}\n\n"
        "Do not include explanations, markdown, or any other text — only the JSON object.\n\n"
        "Here are the reports:\n"
        f"{combined}"
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
        raw_response = asyncio.run(_call_openai())

        #  Try to parse JSON safely
        try:
            parsed = json.loads(raw_response)
            return parsed  # return Python dict if valid JSON
        except json.JSONDecodeError:
            # fallback: return raw string if not valid JSON
            return {"error": "Failed to parse AI JSON", "raw": raw_response}

    except Exception as e:
        return {"error": f"AI analysis failed: {e}"}
