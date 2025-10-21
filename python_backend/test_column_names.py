import pandas as pd

# Ändra till din filväg
df = pd.read_excel("data_from_ikea/ikea_factory_data.xlsx")

print("Kolumner funna i Excel:")
for col in df.columns:
    print(f"- {col}")