from excel_data_handler import load_excel, apply_filters
from ai_analysis import analyze_descriptions
import sys
sys.stdout.reconfigure(encoding='utf-8')
# Load Excel
df = load_excel()

# Define filters (example)
filters = {
    "Factory": "Kazlu Ruda Board",
    "Category": "Incident",
}

# Run the filter logic
result = apply_filters(df, filters, threshold=70, limit=10)


# Print the full prompt that would be sent to OpenAI
print("\nGenerated OpenAI prompt:\n")
print(result["descriptions"])
