import os
import logging
import pandas as pd
import numpy as np
from rapidfuzz import fuzz

logging.basicConfig(level=logging.INFO)

BASE_DIR = os.path.dirname(__file__)
DEFAULT_PATH = os.path.join(BASE_DIR, "data_from_ikea", "ikea_factory_data.xlsx")

def load_excel(file_path: str = DEFAULT_PATH):
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

def normalize_input(user_input: str):
    if not user_input:
        return user_input
    return str(user_input).strip().lower()

def fuzzy_filter(df_local, column, user_input, threshold):
    cleaned_col = df_local[column].fillna("").astype(str).str.lower().str.strip()
    cleaned_input = str(user_input).lower().strip()
    mask = cleaned_col.apply(lambda x: fuzz.ratio(x, cleaned_input) >= threshold)
    return df_local[mask]

def apply_filters(df, filters: dict, threshold: int = 60, limit: int = 100):
    filtered_df = df.copy()
    filtered_df.columns = filtered_df.columns.str.strip().str.lower()

    for column, value in filters.items():
        column_lower = column.lower()
        if column_lower not in filtered_df.columns:
            raise ValueError(f"Kolumn '{column}' finns inte i datan.")

        if isinstance(value, dict) and ("from" in value or "to" in value):
            filtered_df[column_lower] = pd.to_datetime(filtered_df[column_lower], errors="coerce")
            from_date = pd.to_datetime(value.get("from"), errors="coerce") if value.get("from") else None
            to_date = pd.to_datetime(value.get("to"), errors="coerce") if value.get("to") else None
            if from_date is not None:
                filtered_df = filtered_df[filtered_df[column_lower] >= from_date]
            if to_date is not None:
                filtered_df = filtered_df[filtered_df[column_lower] <= to_date]
            continue

        normalized_value = normalize_input(value)
        filtered_df = fuzzy_filter(filtered_df, column_lower, normalized_value, threshold)

    accident_cols = [c for c in filtered_df.columns if "accident" in c]
    incident_cols = [c for c in filtered_df.columns if "incident" in c]

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

    location_counts = {}
    if "where did it happened" in filtered_df.columns:
        location_series = filtered_df["where did it happened"].dropna().astype(str)
        for loc in location_series:
            loc = loc.strip()
            if not loc:
                continue
            location_counts[loc] = location_counts.get(loc, 0) + 1

    descriptions = []
    if "what happened" in filtered_df.columns and "where did it happened" in filtered_df.columns:
        combined = (
            filtered_df.apply(
                lambda row: f"Location: {row['where did it happened']} — Incident: {row['what happened']}",
                axis=1,
            )
            .dropna()
            .astype(str)
            .tolist()
        )
        descriptions = combined

    return {
        "aggregates": {
            "rows": len(filtered_df),
            "accidents": int(accident_sum),
            "incidents": int(incident_sum),
        },
        "location_counts": location_counts,
        "descriptions": descriptions,
    }
