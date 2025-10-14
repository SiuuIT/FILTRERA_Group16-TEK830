# --- excel_data_handler.py ---
# FIXED: Cleaned up and clarified paths, added normalization and fuzzy match utilities.

import os
import logging
import pandas as pd
import numpy as np
from rapidfuzz import fuzz

logging.basicConfig(level=logging.INFO)

BASE_DIR = os.path.dirname(__file__)
DEFAULT_PATH = os.path.join(BASE_DIR, "data_from_ikea", "FY20.xlsx")

def load_excel(file_path: str = DEFAULT_PATH):
    """Load Excel data and sanitize it."""
    try:
        logging.info(f"Laddar Excel-fil från: {file_path}")
        if not os.path.exists(file_path):
            raise FileNotFoundError(file_path)
        df = pd.read_excel(file_path)
        df = df.replace([np.nan, np.inf, -np.inf], None)
        return df
    except Exception as ex:
        logging.exception(f"Fel vid laddning av Excel: {ex}")
        return None

# Optional synonym normalization
def normalize_input(user_input: str):
    if not user_input:
        return user_input
    return str(user_input).strip().lower()

def fuzzy_filter(df_local, column, user_input, threshold):
    """Fuzzy match rows in a DataFrame column."""
    cleaned_col = df_local[column].fillna("").astype(str).str.lower().str.strip()
    cleaned_input = str(user_input).lower().strip()
    mask = cleaned_col.apply(lambda x: fuzz.ratio(x, cleaned_input) >= threshold)
    return df_local[mask]

def apply_filters(df, filters: dict, threshold: int = 60, limit: int = 100):
    """Apply filters, count accidents/incidents, and collect descriptions."""
    filtered_df = df.copy()

    for column, value in filters.items():
        if column not in filtered_df.columns:
            raise ValueError(f"Kolumn '{column}' finns inte i datan.")

        # Date filtering
        if isinstance(value, dict) and ("from" in value or "to" in value):
            filtered_df[column] = pd.to_datetime(filtered_df[column], errors="coerce")
            from_date = pd.to_datetime(value.get("from"), errors="coerce") if value.get("from") else None
            to_date = pd.to_datetime(value.get("to"), errors="coerce") if value.get("to") else None
            if from_date is not None:
                filtered_df = filtered_df[filtered_df[column] >= from_date]
            if to_date is not None:
                filtered_df = filtered_df[filtered_df[column] <= to_date]
            continue

        # Text fuzzy filtering
        normalized_value = normalize_input(value)
        filtered_df = fuzzy_filter(filtered_df, column, normalized_value, threshold)

    # Accident/incident aggregation
    accident_cols = [c for c in filtered_df.columns if "accident" in c.lower()]
    incident_cols = [c for c in filtered_df.columns if "incident" in c.lower()]

    accident_sum = 0
    incident_sum = 0

    for col in accident_cols:
        if pd.api.types.is_numeric_dtype(filtered_df[col]):
            accident_sum += filtered_df[col].sum()
        else:
            accident_sum += filtered_df[col].notna().sum()

    for col in incident_cols:
        if pd.api.types.is_numeric_dtype(filtered_df[col]):
            incident_sum += filtered_df[col].sum()
        else:
            incident_sum += filtered_df[col].notna().sum()

    # Collect description texts if column exists
    # Collect description texts if column exists
    descriptions = []
    if "What happened?" in filtered_df.columns:
        descriptions = filtered_df["What happened?"].dropna().astype(str).tolist()

    return {
        "results": filtered_df.head(limit).to_dict(orient="records"),
        "aggregates": {
            "rows": len(filtered_df),
            "accidents": int(accident_sum),
            "incidents": int(incident_sum),
        },
        "descriptions": descriptions,
    }