import pandas as pd

xls = pd.ExcelFile("gld.xlsx")

i = 0
for sheet in xls.sheet_names:
    df = pd.read_excel(xls, sheet_name=sheet)
    df.to_csv(f"gld.{i}.csv", index=False)
    i += 1
