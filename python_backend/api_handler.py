from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from python_backend.excel_data_handler import load_excel, apply_filters
from python_backend.ai_analysis import analyze_location_and_description
import logging
import pandas as pd
# api_handler.py
# Fixed version with CORS, POST /filter, GET /columns, and GET /unique-values.
#run this by this in terminal 
# source ../.venv/Scripts/activate
# uvicorn python_backend.api_handler:app --reload
#also need to set up api kay at start every server startup $env:OPENAI_API_KEY="sk-your-key-here"
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


@app.post("/filter")
def filter_data(request: FilterRequest):
    """Filter Excel data, count accidents/incidents, and run AI summary."""
    if df is None:
        return JSONResponse(status_code=500, content={"error": "Excel-data kunde inte laddas."})

    try:
        result = apply_filters(df, request.filters, request.threshold, request.limit)

        # Add AI-generated safety summary
        ai_summary = analyze_location_and_description(result.get("descriptions", []))
        print("AI Summary:", ai_summary)  # Debug print
        result["AIAnswer"] = ai_summary
        del result["descriptions"]  # remove raw descriptions from output

        return result

    except ValueError as e:
        logging.exception("Filter error")
        return JSONResponse(status_code=400, content={"error": str(e)})
    except Exception as e:
        logging.exception("Unknown error")
        return JSONResponse(status_code=500, content={"error": str(e)})


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


