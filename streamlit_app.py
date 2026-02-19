import pandas as pd
import streamlit as st
from sqlalchemy import create_engine, text


st.set_page_config(page_title="Products", page_icon="🪑")
st.title("Hello World!")
st.write('This app displays the product table `Tables` from MySQL.')

# Read DB settings from Streamlit secrets
DB_HOST = st.secrets["mysql"]["host"]
DB_PORT = st.secrets["mysql"].get("port", 3306)
DB_USER = st.secrets["mysql"]["user"]
DB_PASSWORD = st.secrets["mysql"]["password"]
DB_NAME = st.secrets["mysql"]["database"]

@st.cache_data(ttl=60)
def load_tables() -> pd.DataFrame:
    engine = create_engine(
        f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )
    query = text("SELECT * FROM `Tables`;")
    with engine.connect() as conn:
        return pd.read_sql(query, conn)

st.header('Products: "Tables"')

try:
    df = load_tables()
    if df.empty:
        st.info("No rows found in the `Tables` table.")
    else:
        st.dataframe(df, use_container_width=True, hide_index=True)
except Exception as e:
    st.error("Could not load data from MySQL.")
    st.exception(e)
