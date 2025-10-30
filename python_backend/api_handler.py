from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from excel_data_handler import load_excel, apply_filters
from ai_analysis import analyze_location_and_description,  rank_incident_severity, interpret_filter_prompt 
import logging
import pandas as pd
# api_handler.py
# Fixed version with CORS, POST /filter, GET /columns, and GET /unique-values.
#run this by this in terminal 
# source .venv/Scripts/activate
#$ source C:/Users/Admin/Desktop/my_projects/TEK830/.venv/Scripts/activate
#cd python_backend
# uvicorn api_handler:app --reload
#also need to set up api key at start every server startup $env:OPENAI_API_KEY="sk-your-key-here"
#http://127.0.0.1:8000/docs debug serber with this
app = FastAPI(title="IKEA Filter API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

df = load_excel()

class FilterRequest(BaseModel):
    filters: dict
    limit: int = 100
    threshold: int = 60


# --- Routes ---
@app.post("/filter")
def filter_data(request: FilterRequest):
    if df is None:
        return JSONResponse(status_code=500, content={"error": "Excel-data kunde inte laddas."})

    try:
        # Filter the dataframe
        result = apply_filters(df, request.filters, request.threshold, request.limit)

        # AI analysis
        ai_summary = analyze_location_and_description(result.get("descriptions", []))
        severity_rankings = rank_incident_severity(result.get("accident_reports", []))

        #  Merge accident reports with AI severity
        merged_reports = []
        if isinstance(severity_rankings, list):
            for r in severity_rankings:
                merged_reports.append({
                    "where": r.get("where") or r.get("location"),
                    "what": r.get("what") or r.get("incident"),
                    "category": r.get("category"),
                    "severity": r.get("severity")
                })

        #  Build heatmap data: count + average severity per location
        heatmap_data = {}
        if isinstance(severity_rankings, list):
            for r in severity_rankings:
                loc = r.get("where")
                sev = r.get("severity")
                if not loc or not isinstance(sev, (int, float)):
                    continue

                if loc not in heatmap_data:
                    heatmap_data[loc] = {"count": 0, "total_severity": 0}

                heatmap_data[loc]["count"] += 1
                heatmap_data[loc]["total_severity"] += sev

        for loc, vals in heatmap_data.items():
            total = vals["total_severity"]
            count = vals["count"]
            heatmap_data[loc]["avg_severity"] = round(total / count, 2)
            del heatmap_data[loc]["total_severity"]

        # Build final combined response
        clean_response = {
            "aggregates": result["aggregates"],
            "location_counts": result["location_counts"],
            "AIAnswer": ai_summary,
            "accident_reports": merged_reports[:20],  # limit to top N if desired
            "heatmap_data": heatmap_data,  # 👈 NEW FIELD
        }

        print(clean_response)
        return clean_response

    except ValueError as e:
        logging.exception("Filter error")
        return JSONResponse(status_code=400, content={"error": str(e)})

    except Exception as e:
        logging.exception("Unknown error")
        return JSONResponse(status_code=500, content={"error": str(e)})




@app.post("/ai-interpret-filters")
def ai_interpret_filters(request: dict):
    prompt = request.get("prompt", "")

    if not prompt:
        return {"error": "Prompt missing."}
    
    available_factories = (
        df["Factory"]
        .dropna()
        .astype(str)
        .unique()
        .tolist()
    )
    return interpret_filter_prompt(prompt,available_factories)



@app.get("/columns")
def list_columns():
    if df is None:
        return JSONResponse(status_code=500, content={"error": "Excel-data kunde inte laddas."})
    return {"columns": df.columns.tolist()}


@app.get("/unique-values")
def get_unique_values(column: str = Query(..., description="Column to fetch unique values from")):
    if df is None:
        return JSONResponse(status_code=500, content={"error": "Excel-data kunde inte laddas."})

    if column not in df.columns:
        return JSONResponse(status_code=400, content={"error": f"Kolumn '{column}' finns inte."})

    unique_values = df[column].dropna().unique().tolist()
    return {"values": unique_values}






