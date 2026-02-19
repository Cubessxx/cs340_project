import pandas as pd
import streamlit as st
from db import get_engine

# Page setup
engine = get_engine()
st.set_page_config(page_title="Reptile Central", page_icon="🦎")



st.title("Welcome to the Reptile Central Database Manager!")
st.write(
    "Use this website to view and manage our animals, products, customers and orders. "
)
st.image("assets/leopard_gecko.jpg", width="content")

