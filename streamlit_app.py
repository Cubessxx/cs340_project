import pandas as pd
import streamlit as st
from sqlalchemy import create_engine, text

st.set_page_config(page_title="Products", page_icon="🪑")
st.title("Hello World!")
st.write("This app connects to MySQL and displays a selected table.")

DB_HOST = st.secrets["mysql"]["host"]
DB_PORT = st.secrets["mysql"].get("port", 3306)
DB_USER = st.secrets["mysql"]["user"]
DB_PASSWORD = st.secrets["mysql"]["password"]
DB_NAME = st.secrets["mysql"]["database"]

@st.cache_resource
def get_engine():
    return create_engine(
        f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )

@st.cache_data(ttl=60)
def list_tables() -> list[str]:
    engine = get_engine()
    q = text(
        """
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = :db
        ORDER BY table_name;
        """
    )
    with engine.connect() as conn:
        rows = conn.execute(q, {"db": DB_NAME}).fetchall()
    return [r[0] for r in rows]

@st.cache_data(ttl=60)
def load_table(table_name: str) -> pd.DataFrame:
    engine = get_engine()
    # Safely quote identifier with backticks (and escape any backticks just in case)
    safe_name = table_name.replace("`", "``")
    q = text(f"SELECT * FROM `{safe_name}`;")
    with engine.connect() as conn:
        return pd.read_sql(q, conn)

try:
    tables = list_tables()

    if not tables:
        st.error(f"No tables found in database `{DB_NAME}`.")
        st.stop()

    st.subheader("Available tables in your database")
    st.write(tables)

    # Try to auto-pick a table named like "Tables" if it exists (case-insensitive)
    default_idx = 0
    for i, t in enumerate(tables):
        if t.lower() == "tables":
            default_idx = i
            break

    selected = st.selectbox("Select a table to display", tables, index=default_idx)

    st.header(f'Displaying table: `{selected}`')
    df = load_table(selected)

    if df.empty:
        st.info("This table has no rows.")
    else:
        st.dataframe(df, use_container_width=True, hide_index=True)

except Exception as e:
    st.error("Could not load data from MySQL.")
    st.exception(e)
