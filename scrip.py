# %%
import datetime
import sys
import os
import pandas as pd

today = datetime.date.today()
# import rich.pretty
#
# rich.pretty.install()

# %%
print(f"Sys Arguments: {sys.argv}")

cwd = os.getcwd()
cwd
today
# print(sys.flags)
# print(sys.path)
#
# print(os.getcwd())

# %%
df = pd.read_csv("~/data/personality_dataset.csv")

df.head()
