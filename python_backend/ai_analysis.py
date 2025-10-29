import os
from openai import OpenAI
import asyncio
import json

def analyze_descriptions(descriptions: list[str]) -> str:
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
        return asyncio.run(_call_openai())
    except Exception as e:
        return f"AI analysis failed: {e}"


#  FIXED — added return logic
def analyze_location_and_description(descriptions: list[str]):
    """Analyze and summarize incident descriptions by location using OpenAI."""
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
        "Return your response strictly as a valid JSON object where each key is the location name and each value "
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
        raw_response = asyncio.run(_call_openai())

        try:
            parsed = json.loads(raw_response)
            return parsed
        except json.JSONDecodeError:
            return {"error": "Failed to parse AI JSON", "raw": raw_response}

    except Exception as e:
        return {"error": f"AI analysis failed: {e}"}


def rank_incident_severity(accident_reports: list[dict]) -> list[dict]:
    if not accident_reports:
        return []

    combined = "\n".join([
        f"where: {r.get('where')} — what: {r.get('what')} — category: {r.get('category')}"
        for r in accident_reports[:50]
    ])

    prompt = (
        "You are an IKEA workplace safety assessor. Below are short incident reports, "
        "each with a location, description, and category (accident or incident).\n\n"
        "For each, assign a SEVERITY score between 1 and 10 based on risk, potential harm, "
        "and seriousness (1 = trivial, 10 = severe or life-threatening).\n\n"
        "Return your response strictly as a valid JSON array, each element with:\n"
        "  - where\n"
        "  - what\n"
        "  - category\n"
        "  - severity (integer 1–10)\n\n"
        "Example:\n"
        "[\n"
        "  {\"where\": \"Warehouse Zone B\", \"what\": \"Forklift collision\", \"category\": \"accident\", \"severity\": 8},\n"
        "  {\"where\": \"Packaging Line\", \"what\": \"Minor spill\", \"category\": \"incident\", \"severity\": 3}\n"
        "]\n\n"
        "Do not include explanations or markdown. Only return valid JSON.\n\n"
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
        raw_response = asyncio.run(_call_openai())

        try:
            parsed = json.loads(raw_response)
            return parsed
        except json.JSONDecodeError:
            return {"error": "Failed to parse AI JSON", "raw": raw_response}

    except Exception as e:
        return {"error": f"AI analysis failed: {e}"}


def interpret_filter_prompt(prompt: str, available_factories: list[str]) -> dict:
    """Interpret a natural language prompt into structured filter criteria."""
    #remake prompt so gives factory, response body is now wrong
    factories_list = ", ".join(available_factories[:50])
    system_prompt = (
        "You are an assistant for a factory safety analytics system. "
        "Convert the user's request into a JSON object of filters. "
        "Only use factory names from the following list:\n"
        f"{factories_list}\n\n"
        "If the user mentions a location that does not match any in the list, "
        "choose the closest valid one by meaning.\n\n"
        "Available filter fields: 'where did it happened', 'category', 'date'.\n"
        "Always return a valid JSON structure like:\n"
        "{\n"
        "  'filters': {\n"
        "    'Factory': 'Ikea Sweden',\n"
        "    'date': {'from': '2025-01-01', 'to': '2025-12-31'}\n"
        "  }\n"
        "}"
    )

    async def _call_openai():
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        response = await asyncio.to_thread(
            client.chat.completions.create,
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
        )
        print(response.choices[0].message.content.strip())
        return response.choices[0].message.content.strip()
        
    try:
        raw = asyncio.run(_call_openai())
        return json.loads(raw)
    except Exception as e:
        return {"error": f"Failed to interpret prompt: {e}"}
    