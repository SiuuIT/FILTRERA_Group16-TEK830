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
