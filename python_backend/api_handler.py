# api_handler.py
# Fixed version with CORS, POST /filter, GET /columns, and GET /unique-values.
#run this by this in terminal 
# source ../.venv/Scripts/activate
# uvicorn python_backend.api_handler:app --reload

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from python_backend.excel_data_handler import load_excel, normalize_input, fuzzy_filter

app = FastAPI(title="IKEA Filter API")

# Allow Flutter to communicate with FastAPI
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load Excel when the server starts
df = load_excel()

# Model for POST body
class FilterRequest(BaseModel):
    filters: dict
    limit: int = 100
    threshold: int = 60



@app.get("/columns")
def list_columns():
    """List all available columns in the Excel file."""
    if df is None:
        return JSONResponse(status_code=500, content={"error": "Excel-data kunde inte laddas."})
    return {"columns": df.columns.tolist()}


@app.get("/unique-values")
def get_unique_values(column: str = Query(..., description="Column to fetch unique values from")):
    """Return all unique values for a specific column."""
    if df is None:
        return JSONResponse(status_code=500, content={"error": "Excel-data kunde inte laddas."})

    if column not in df.columns:
        return JSONResponse(
            status_code=400,
            content={"error": f"Kolumn '{column}' finns inte.", "columns": df.columns.tolist()},
        )

    unique_values = df[column].dropna().unique().tolist()
    return {"values": unique_values}


@app.post("/filter")
def filter_data(filters: FilterRequest):
    """Filter the Excel file based on multiple columns and values."""
    if df is None:
        return JSONResponse(status_code=500, content={"error": "Excel-data kunde inte laddas."})

    filtered_df = df.copy()

    # Apply each filter
    for column, value in filters.filters.items():
        if column not in filtered_df.columns:
            return JSONResponse(
                status_code=400,
                content={"error": f"Kolumn '{column}' finns inte.", "columns": df.columns.tolist()},
            )

        normalized_value = normalize_input(value)
        filtered_df = fuzzy_filter(filtered_df, column, normalized_value, filters.threshold)
    
    
    return {"results": filtered_df.head(filters.limit).to_dict(orient="records")}

