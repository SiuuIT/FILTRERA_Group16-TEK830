from fastapi import FastAPI, Query
from fastapi.responses import JSONResponse
from python_backend.excel_data_handler import load_excel, normalize_input, fuzzy_filter

# Initiera FastAPI
app = FastAPI()

# Ladda Excel när servern startar
df = load_excel()

@app.get("/filter")
def filter_data(
    column: str = Query(..., description="Kolumn att filtrera på"),
    value: str = Query(..., description="Sökterm att matcha"),
    limit: int = Query(100, description="Max antal rader att returnera"),
    threshold: int = Query(60, description="Likhetströskel (0–100)")
):
    if df is None:
        return JSONResponse(status_code=500, content={"error": "Excel-data kunde inte laddas."})
    if column not in df.columns:
        return JSONResponse(
            status_code=400,
            content={"error": f"Kolumn '{column}' finns inte.", "columns": df.columns.tolist()}
        )

    normalized_value = normalize_input(value)
    filtered = fuzzy_filter(df, column, normalized_value, threshold).head(limit)
    return filtered.to_dict(orient="records")

@app.get("/columns")
def list_columns():
    if df is None:
        return JSONResponse(status_code=500, content={"error": "Excel-data kunde inte laddas."})
    return {"columns": df.columns.tolist()}
