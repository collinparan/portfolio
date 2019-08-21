import pandas as pd
import numpy as np
from sqlalchemy import create_engine
import psycopg2 
import io

df = pd.read_csv('http://files.zillowstatic.com/research/public/Neighborhood/Neighborhood_MedianValuePerSqft_AllHomes.csv')
engine = create_engine('postgresql+psycopg2://username:password@host:port/database')
df.head(0).to_sql('zillow', engine, if_exists='replace',index=False) #truncates the table

conn = engine.raw_connection()
cur = conn.cursor()
output = io.StringIO()
df.to_csv(output, sep='\t', header=False, index=False)
output.seek(0)
contents = output.getvalue()
cur.copy_from(output, 'zillow', null="")
conn.commit()
