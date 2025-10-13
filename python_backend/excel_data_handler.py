import os
import logging
import pandas as pd
import numpy as np
from rapidfuzz import fuzz

logging.basicConfig(level=logging.INFO)

BASE_DIR = os.path.dirname(__file__)
DEFAULT_PATH = os.path.join(BASE_DIR, "..", "data_from_ikea", "FY20.xlsx")

# --- Ladda data ---
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

# --- Synonymer ---
synonyms = {
    "lavatory": ["toilet", "lavatory", "WC", "washroom"],
    "coworker": ["coworker", "co-worker", "colleague"],
    "office": ["office", "workspace", "workplace"]
}

def normalize_input(user_input: str):
    if not user_input:
        return user_input
    for key, variants in synonyms.items():
        if str(user_input).lower() in [v.lower() for v in variants]:
            return key
    return user_input

# --- Fuzzy matchning ---
def fuzzy_filter(df_local, column, user_input, threshold):
    cleaned_column = df_local[column].fillna("").astype(str).str.strip().str.lower()
    cleaned_input = str(user_input).strip().lower()
    mask = cleaned_column.apply(lambda x: fuzz.ratio(x, cleaned_input) >= threshold)
    return df_local[mask]
