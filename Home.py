import pandas as pd
import streamlit as st
from db import get_engine

# Page setup
st.set_page_config(page_title="Reptile Central", page_icon="🦎")
st.title("Animals")

engine = get_engine()

# Load Animals table
query = "SELECT * FROM Animals;"
df = pd.read_sql(query, engine)

# Display table
st.dataframe(df, use_container_width=True, hide_index=True)
