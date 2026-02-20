import pandas as pd
import streamlit as st
from sqlalchemy import text
from db import get_engine
from reset_button import render_reset_button

st.set_page_config(page_title="Reptile Central - Customers",page_icon ="???????" , layout="wide")
st.title("Customers")

engine = get_engine()
render_reset_button(engine, key='reset_db_button')

# Views
customers_query = """
SELECT *
FROM v_browse_customers_page;
"""

# Stored Procedure Calls
delete_query = """
CALL sp_delete_customer(:customerID_selected_from_browse_customers_page);
"""

insert_query = """
CALL sp_insert_customer(:firstNameInput, :lastNameInput, :emailInput, :phoneNumberInput);
"""

select_one_query = """
CALL sp_select_one_customer(:customerID_selected_from_browse_customers_page);
"""

update_query = """
CALL sp_update_customer(:emailInput, :phoneNumberInput, :customerID_from_update_customer_form);
"""

# Load customers once per run
df = pd.read_sql(customers_query, engine)
if not df.empty:
    df["Customer Name"] = (
        df["First Name"].fillna("").astype(str).str.strip() + " " +
        df["Last Name"].fillna("").astype(str).str.strip()
    ).str.strip()
    customer_options = df.index.tolist()
else:
    customer_options = []

# Tabs
tab_browse, tab_create, tab_update, tab_delete = st.tabs(
    ["Browse Customers", "Create Customer", "Update Customer", "Delete Customer"]
)


# Browse Customers
with tab_browse:
    st.subheader("Browse Customers")
    st.dataframe(df, width='stretch', hide_index=True)


# Create Customer
with tab_create:
    st.subheader("Create Customer")

    with st.form("create_customer", clear_on_submit=True):
        first = st.text_input("First Name")
        last = st.text_input("Last Name")
        email = st.text_input("Email")
        phone = st.text_input("Phone Number")
        submitted = st.form_submit_button("Create Customer")

    if submitted:
        with engine.begin() as conn:
            conn.execute(
                text(insert_query),
                {
                    "firstNameInput": first,
                    "lastNameInput": last,
                    "emailInput": email,
                    "phoneNumberInput": phone,
                },
            )
        st.rerun()


# Update Customer
with tab_update:
    st.subheader("Update Customer")

    if df.empty:
        st.write("No customers found.")
    else:
        selected_idx = st.selectbox(
            "Select Customer",
            customer_options,
            format_func=lambda i: df.loc[i, "Customer Name"],
            key="update_customer",
        )
        selected_id = int(df.loc[selected_idx, "Customer ID"])

        current = pd.read_sql(
            text(select_one_query),
            engine,
            params={"customerID_selected_from_browse_customers_page": selected_id},
        )

        email_new = st.text_input("New Email", value=current.loc[0, "Email"])
        phone_new = st.text_input("New Phone Number", value=current.loc[0, "Phone Number"])

        if st.button("Update Customer"):
            with engine.begin() as conn:
                conn.execute(
                    text(update_query),
                    {
                        "emailInput": email_new,
                        "phoneNumberInput": phone_new,
                        "customerID_from_update_customer_form": selected_id,
                    },
                )
            st.rerun()


# Delete Customer
with tab_delete:
    st.subheader("Delete Customer")

    if df.empty:
        st.write("No customers to delete.")
    else:
        selected_idx = st.selectbox(
            "Select Customer",
            customer_options,
            format_func=lambda i: df.loc[i, "Customer Name"],
            key="delete_customer",
        )
        selected_id = int(df.loc[selected_idx, "Customer ID"])

        if st.button("Delete Customer"):
            with engine.begin() as conn:
                conn.execute(
                    text(delete_query),
                    {"customerID_selected_from_browse_customers_page": selected_id},
                )
            st.rerun()
