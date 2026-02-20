import pandas as pd
import streamlit as st
from sqlalchemy import text
from db import get_engine
from reset_button import render_reset_button

st.set_page_config(page_title="Reptile Central - Products", page_icon="📦", layout="wide")
st.title("Products")

engine = get_engine()
render_reset_button(engine, key='reset_db_button')

# Views
products_query = """
SELECT *
FROM v_browse_products_page;
"""

product_types_for_entry_query = """
SELECT *
FROM v_browse_product_types_for_product_entry;
"""

# Stored Procedure Calls
delete_query = """
CALL sp_delete_product(:productID_selected_from_browse_products_page);
"""

insert_query = """
CALL sp_insert_product(:productNameInput,
                       :productTypeCode_selected_from_create_product_form,
                       :priceInput,
                       :stockInput);
"""

select_one_query = """
CALL sp_select_one_product(:productID_selected_from_browse_products_page);
"""

update_query = """
CALL sp_update_product(:productNameInput,
                       :productTypeCode_selected_from_update_product_form,
                       :priceInput,
                       :stockInput,
                       :productID_from_update_product_form);
"""

# Load products once per run
products_df = pd.read_sql(products_query, engine)
product_types_for_entry_df = pd.read_sql(product_types_for_entry_query, engine)

if not products_df.empty:
    product_options = products_df.index.tolist()
else:
    product_options = []

if not product_types_for_entry_df.empty:
    type_code_options = product_types_for_entry_df["Product Type Code"].astype(str).tolist()
    type_name_lookup = dict(
        zip(
            product_types_for_entry_df["Product Type Code"].astype(str),
            product_types_for_entry_df["Product Type Name"].astype(str),
        )
    )
else:
    type_code_options = []
    type_name_lookup = {}

# Tabs
tab_browse, tab_create, tab_update, tab_delete = st.tabs(
    ["Browse Products", "Create Product", "Update Product", "Delete Product"]
)


# Browse Products
with tab_browse:
    st.subheader("Browse Products")
    st.dataframe(products_df, width='stretch', hide_index=True)


# Create Product
with tab_create:
    st.subheader("Create Product")

    if not type_code_options:
        st.write("No product types found. Use the Product Types page first.")
    else:
        with st.form("create_product", clear_on_submit=True):
            product_name = st.text_input("Product Name")
            product_type_code = st.selectbox(
                "Product Type",
                type_code_options,
                format_func=lambda c: f"{c} - {type_name_lookup.get(c, '')}",
                key="create_product_type",
            )
            price = st.number_input(
                "Price",
                min_value=0.0,
                step=0.01,
                format="%.2f",
            )
            stock = st.number_input("Stock", min_value=0, step=1)
            submitted = st.form_submit_button("Create Product")

        if submitted:
            with engine.begin() as conn:
                conn.execute(
                    text(insert_query),
                    {
                        "productNameInput": product_name,
                        "productTypeCode_selected_from_create_product_form": product_type_code,
                        "priceInput": float(price),
                        "stockInput": int(stock),
                    },
                )
            st.rerun()


# Update Product
with tab_update:
    st.subheader("Update Product")

    if products_df.empty:
        st.write("No products found.")
    elif not type_code_options:
        st.write("No product types found. Use the Product Types page first.")
    else:
        selected_idx = st.selectbox(
            "Select Product",
            product_options,
            format_func=lambda i: products_df.loc[i, "Product Name"],
            key="update_product_select",
        )
        selected_id = int(products_df.loc[selected_idx, "Product ID"])

        current = pd.read_sql(
            text(select_one_query),
            engine,
            params={"productID_selected_from_browse_products_page": selected_id},
        )

        current_type_code = str(current.loc[0, "Product Type Code"])
        type_index = 0
        if current_type_code in type_code_options:
            type_index = type_code_options.index(current_type_code)

        product_name_new = st.text_input("Product Name", value=current.loc[0, "Product Name"])
        product_type_code_new = st.selectbox(
            "Product Type",
            type_code_options,
            index=type_index,
            format_func=lambda c: f"{c} - {type_name_lookup.get(c, '')}",
            key="update_product_type",
        )
        price_new = st.number_input(
            "Price",
            min_value=0.0,
            step=0.01,
            format="%.2f",
            value=float(current.loc[0, "Price"]),
            key="update_product_price",
        )
        stock_new = st.number_input(
            "Stock",
            min_value=0,
            step=1,
            value=int(current.loc[0, "Stock"]),
            key="update_product_stock",
        )

        if st.button("Update Product"):
            with engine.begin() as conn:
                conn.execute(
                    text(update_query),
                    {
                        "productNameInput": product_name_new,
                        "productTypeCode_selected_from_update_product_form": product_type_code_new,
                        "priceInput": float(price_new),
                        "stockInput": int(stock_new),
                        "productID_from_update_product_form": selected_id,
                    },
                )
            st.rerun()


# Delete Product
with tab_delete:
    st.subheader("Delete Product")

    if products_df.empty:
        st.write("No products to delete.")
    else:
        selected_idx = st.selectbox(
            "Select Product",
            product_options,
            format_func=lambda i: products_df.loc[i, "Product Name"],
            key="delete_product_select",
        )
        selected_id = int(products_df.loc[selected_idx, "Product ID"])

        if st.button("Delete Product"):
            with engine.begin() as conn:
                conn.execute(
                    text(delete_query),
                    {"productID_selected_from_browse_products_page": selected_id},
                )
            st.rerun()
