import pandas as pd
import streamlit as st
from sqlalchemy import text
from db import get_engine
from reset_button import render_reset_button

st.set_page_config(page_title="Reptile Central - Product Types", page_icon="🏷️", layout="wide")
st.title("Product Types")

engine = get_engine()
render_reset_button(engine, key='reset_db_button')

# Views
product_types_query = """
SELECT *
FROM v_browse_product_types_page;
"""

# Stored Procedure Calls
delete_query = """
CALL sp_delete_product_type(:productTypeCode_selected_from_browse_product_types_page);
"""

insert_query = """
CALL sp_insert_product_type(:productTypeCodeInput, :productTypeNameInput);
"""

select_one_query = """
CALL sp_select_one_product_type(:productTypeCode_selected_from_browse_product_types_page);
"""

update_query = """
CALL sp_update_product_type(:productTypeNameInput,
                            :productTypeCode_from_update_product_type_form);
"""

# Load product types once per run
df = pd.read_sql(product_types_query, engine)

if not df.empty:
    product_type_options = df.index.tolist()
else:
    product_type_options = []

# Tabs
tab_browse, tab_create, tab_update, tab_delete = st.tabs(
    ["Browse Product Types", "Create Product Type", "Update Product Type", "Delete Product Type"]
)


# Browse Product Types
with tab_browse:
    st.subheader("Browse Product Types")
    st.dataframe(df, width='stretch', hide_index=True)


# Create Product Type
with tab_create:
    st.subheader("Create Product Type")

    with st.form("create_product_type", clear_on_submit=True):
        product_type_code = st.text_input("Product Type Code")
        product_type_name = st.text_input("Product Type Name")
        submitted = st.form_submit_button("Create Product Type")

    if submitted:
        with engine.begin() as conn:
            conn.execute(
                text(insert_query),
                {
                    "productTypeCodeInput": product_type_code,
                    "productTypeNameInput": product_type_name,
                },
            )
        st.rerun()


# Update Product Type
with tab_update:
    st.subheader("Update Product Type")

    if df.empty:
        st.write("No product types found.")
    else:
        selected_idx = st.selectbox(
            "Select Product Type",
            product_type_options,
            format_func=lambda i: (
                f"{df.loc[i, 'Product Type Code']} - "
                f"{df.loc[i, 'Product Type Name']}"
            ),
            key="update_product_type_select",
        )
        selected_code = str(df.loc[selected_idx, "Product Type Code"])

        current = pd.read_sql(
            text(select_one_query),
            engine,
            params={"productTypeCode_selected_from_browse_product_types_page": selected_code},
        )

        product_type_name_new = st.text_input(
            "Product Type Name",
            value=current.loc[0, "Product Type Name"],
        )

        if st.button("Update Product Type"):
            with engine.begin() as conn:
                conn.execute(
                    text(update_query),
                    {
                        "productTypeNameInput": product_type_name_new,
                        "productTypeCode_from_update_product_type_form": selected_code,
                    },
                )
            st.rerun()


# Delete Product Type
with tab_delete:
    st.subheader("Delete Product Type")

    if df.empty:
        st.write("No product types to delete.")
    else:
        selected_idx = st.selectbox(
            "Select Product Type",
            product_type_options,
            format_func=lambda i: (
                f"{df.loc[i, 'Product Type Code']} - "
                f"{df.loc[i, 'Product Type Name']}"
            ),
            key="delete_product_type_select",
        )
        selected_code = str(df.loc[selected_idx, "Product Type Code"])
        if st.button("Delete Product Type"):
            with engine.begin() as conn:
                conn.execute(
                    text(delete_query),
                    {"productTypeCode_selected_from_browse_product_types_page": selected_code},
                )
            st.rerun()
