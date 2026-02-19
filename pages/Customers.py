import pandas as pd
import streamlit as st
from sqlalchemy import text
from db import get_engine

st.set_page_config(page_title="Reptile Central - Customers", page_icon="👤", layout="wide")
st.title("Customers")

engine = get_engine()

# Our DML Queries
customers_query = """
SELECT Customers.customerID AS "Customer ID",
       Customers.firstName AS "First Name",
       Customers.lastName AS "Last Name",
       Customers.email AS "Email",
       Customers.phoneNumber AS "Phone Number",
       COUNT(Orders.orderID) AS "Active Orders"
FROM Customers
LEFT JOIN Orders
       ON Orders.customerID = Customers.customerID
GROUP BY Customers.customerID,
         Customers.firstName,
         Customers.lastName,
         Customers.email,
         Customers.phoneNumber
ORDER BY Customers.customerID;
"""

delete_query = """
DELETE FROM Customers
WHERE Customers.customerID = :customerID_selected_from_browse_customers_page;
"""

insert_query = """
INSERT INTO Customers (firstName, lastName, email, phoneNumber)
VALUES (:firstNameInput, :lastNameInput, :emailInput, :phoneNumberInput);
"""

select_one_query = """
SELECT Customers.customerID AS "Customer ID",
       Customers.firstName AS "First Name",
       Customers.lastName AS "Last Name",
       Customers.email AS "Email",
       Customers.phoneNumber AS "Phone Number"
FROM Customers
WHERE Customers.customerID = :customerID_selected_from_browse_customers_page;
"""

update_query = """
UPDATE Customers
SET Customers.email = :emailInput,
    Customers.phoneNumber = :phoneNumberInput
WHERE Customers.customerID = :customerID_from_update_customer_form;
"""

# Load customers once per run
df = pd.read_sql(customers_query, engine)

# Build picker using aliased column names
if not df.empty:
    picker_df = df[["Customer ID", "First Name", "Last Name"]].copy()
    picker_df["Display Name"] = (
        picker_df["First Name"].fillna("") + " " +
        picker_df["Last Name"].fillna("")
    ).str.strip()
else:
    picker_df = df

# Tabs
tab_browse, tab_create, tab_update, tab_delete = st.tabs(
    ["Browse Customers", "Create Customer", "Update Customer", "Delete Customer"]
)

# ---------------------------
# Browse Customers
# ---------------------------
with tab_browse:
    st.subheader("Browse Customers")
    st.dataframe(df, use_container_width=True, hide_index=True)

# ---------------------------
# Create Customer
# ---------------------------
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

# ---------------------------
# Update Customer
# ---------------------------
with tab_update:
    st.subheader("Update Customer")

    if df.empty:
        st.write("No customers found.")
    else:
        selected_name = st.selectbox(
            "Select Customer",
            picker_df["Display Name"].tolist(),
            key="update_customer"
        )

        selected_id = int(
            picker_df.loc[picker_df["Display Name"] == selected_name, "Customer ID"].iloc[0]
        )

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

# ---------------------------
# Delete Customer
# ---------------------------
with tab_delete:
    st.subheader("Delete Customer")

    if df.empty:
        st.write("No customers to delete.")
    else:
        selected_name = st.selectbox(
            "Select Customer",
            picker_df["Display Name"].tolist(),
            key="delete_customer"
        )

        selected_id = int(
            picker_df.loc[picker_df["Display Name"] == selected_name, "Customer ID"].iloc[0]
        )

        if st.button("Delete Customer"):
            with engine.begin() as conn:
                conn.execute(
                    text(delete_query),
                    {"customerID_selected_from_browse_customers_page": selected_id},
                )
            st.rerun()
