import pandas as pd
import streamlit as st
from sqlalchemy import create_engine

st.set_page_config(page_title="Reptile Central - Products", page_icon="🛒")
st.title("Products")

DB_HOST = st.secrets["mysql"]["host"]
DB_PORT = st.secrets["mysql"].get("port", 3306)
DB_USER = st.secrets["mysql"]["user"]
DB_PASSWORD = st.secrets["mysql"]["password"]
DB_NAME = st.secrets["mysql"]["database"]

engine = create_engine(
    f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

query = "SELECT * FROM Products;"
df = pd.read_sql(query, engine)

st.dataframe(df, use_container_width=True, hide_index=True)
