import pandas as pd
import streamlit as st
from sqlalchemy import text
from db import get_engine
from reset_button import render_reset_button

st.set_page_config(page_title="Reptile Central - Orders",page_icon="??", layout="wide")
st.title("Orders")

engine = get_engine()
render_reset_button(engine, key='reset_db_button')


# Views
orders_query = """
SELECT *
FROM v_browse_orders_page;
"""

order_details_query = """
SELECT *
FROM v_browse_order_details_page
WHERE `Order ID` = :orderID_selected_from_browse_orders_page;
"""

products_query = """
SELECT *
FROM v_browse_products_for_order_entry;
"""

customers_picker_query = """
SELECT *
FROM v_browse_customers_for_order_entry;
"""

employees_picker_query = """
SELECT *
FROM v_browse_employees_for_order_entry;
"""


# Stored Procedures
delete_order_query = """
CALL sp_delete_order(:orderID_selected_from_browse_orders_page);
"""

insert_order_query = """
CALL sp_insert_order(:customerID_selected_from_create_order_form,
                     :employeeID_selected_from_create_order_form);
"""

upsert_order_detail_query = """
CALL sp_upsert_order_detail(:orderID_from_create_order_form,
                            :productIDInput,
                            :quantityInput);
"""

# Load SQL Data
orders_df = pd.read_sql(orders_query, engine)
customers_df = pd.read_sql(customers_picker_query, engine)
employees_df = pd.read_sql(employees_picker_query, engine)
products_df = pd.read_sql(products_query, engine)

if not customers_df.empty:
    customers_df["Customer Name"] = (
        customers_df["First Name"].fillna("").astype(str).str.strip() + " " +
        customers_df["Last Name"].fillna("").astype(str).str.strip()
    ).str.strip()

if not employees_df.empty:
    employees_df["Employee Name"] = (
        employees_df["First Name"].fillna("").astype(str).str.strip() + " " +
        employees_df["Last Name"].fillna("").astype(str).str.strip()
    ).str.strip()

orders_df["Customer Name"] = (
    orders_df["Customer First Name"].fillna("").astype(str).str.strip() + " " +
    orders_df["Customer Last Name"].fillna("").astype(str).str.strip()
).str.strip()
orders_df["Assigned Employee"] = (
    orders_df["Employee First Name"].fillna("").astype(str).str.strip() + " " +
    orders_df["Employee Last Name"].fillna("").astype(str).str.strip()
).str.strip()

orders_browse_df = orders_df.rename(
    columns={
        "Customer First Name": "First Name",
        "Customer Last Name": "Last Name",
    }
)
orders_browse_df = orders_browse_df[
    ["Order ID", "Order Date", "First Name", "Last Name", "Assigned Employee", "Order Total"]
]


def format_order_option(i: int) -> str:
    return f"Order ID: {int(orders_df.loc[i, 'Order ID'])} Name: {orders_df.loc[i, 'Customer Name']}"





# Tabs
tab_browse, tab_update, tab_manage = st.tabs(
    ["Browse Orders", "View or Update Order Details", "Create or Delete Order"]
)



# Browse Orders Tab
with tab_browse:
    st.write("View Our Order Records Below:")

    if orders_df.empty:
        st.write("No orders found.")
    else:
        st.dataframe(orders_browse_df, width='stretch', hide_index=True)


# View and Update Order Details
with tab_update:
    if orders_df.empty:
        st.write("No orders found.")
    else:
        st.write("Select an order to view or edit")

        order_options = orders_df.index.tolist()
        selected_order_idx = st.selectbox(
            "Order",
            order_options,
            format_func=format_order_option,
            key="update_order_select",
        )
        selected_order_id = int(orders_df.loc[selected_order_idx, "Order ID"])

        details_df = pd.read_sql(
            text(order_details_query),
            engine,
            params={"orderID_selected_from_browse_orders_page": selected_order_id},
        )

        if not details_df.empty:
            st.dataframe(details_df, width='stretch', hide_index=True)
        else:
            st.write("No line items for this order.")

        st.divider()
        st.subheader("Update or Add Items")
        st.write("select an item to add or update in the order")

        if products_df.empty:
            st.write("No products found.")
        else:
            item_options = products_df.index.tolist()
            selected_item_idx = st.selectbox(
                "Select Item",
                item_options,
                format_func=lambda i: products_df.loc[i, "Product Name"],
                key="update_or_add_item_select",
            )
            qty = st.number_input(
                "Quantity:",
                min_value=1,
                step=1,
                value=1,
                key="update_or_add_item_qty",
            )

            if st.button("Update or Add Item"):
                with engine.begin() as conn:
                    conn.execute(
                        text(upsert_order_detail_query),
                        {
                            "orderID_from_create_order_form": selected_order_id,
                            "productIDInput": int(products_df.loc[selected_item_idx, "Product ID"]),
                            "quantityInput": int(qty),
                        },
                    )
                st.rerun()


# Create and Delete Order Tab
with tab_manage:
    st.subheader("Create Order")
    st.write("Create a new order in the system with a given customer and assigned employee.")

    if customers_df.empty or employees_df.empty or products_df.empty:
        st.write("Missing reference data (customers, employees, or products).")
    else:
        entry_df = products_df[["Product ID", "Product Name", "Unit Price"]].copy()
        entry_df["Quantity"] = 0

        with st.form("create_order_form", clear_on_submit=True):
            customer_options = customers_df.index.tolist()
            customer_idx = st.selectbox(
                "Customer",
                customer_options,
                format_func=lambda i: customers_df.loc[i, "Customer Name"],
                key="create_order_customer",
            )

            employee_options = employees_df.index.tolist()
            employee_idx = st.selectbox(
                "Assigned Employee",
                employee_options,
                format_func=lambda i: employees_df.loc[i, "Employee Name"],
                key="create_order_employee",
            )

            st.caption("Click on the quantities tab to adjust the quantity for any product")
            edited_df = st.data_editor(
                entry_df,
                width='stretch',
                hide_index=True,
                disabled=["Product ID", "Product Name", "Unit Price"],
                column_config={
                    "Quantity": st.column_config.NumberColumn(
                        "Quantity",
                        min_value=0,
                        step=1,
                    )
                },
                key="create_order_products_editor",
            )

            submitted = st.form_submit_button("Create Order")

        if submitted:
            customer_id = int(customers_df.loc[customer_idx, "Customer ID"])
            employee_id = int(employees_df.loc[employee_idx, "Employee ID"])

            items = edited_df.copy()
            items["Quantity"] = pd.to_numeric(items["Quantity"], errors="coerce").fillna(0).astype(int)
            items = items[items["Quantity"] > 0]

            if items.empty:
                st.write("No quantities entered. Nothing to create.")
            else:
                with engine.begin() as conn:
                    result = conn.execute(
                        text(insert_order_query),
                        {
                            "customerID_selected_from_create_order_form": customer_id,
                            "employeeID_selected_from_create_order_form": employee_id,
                        },
                    )
                    row = result.fetchone()
                    result.close()
                    if row is None:
                        raise RuntimeError("sp_insert_order did not return the new orderID.")
                    new_order_id = int(row[0])

                    for _, r in items.iterrows():
                        conn.execute(
                            text(upsert_order_detail_query),
                            {
                                "orderID_from_create_order_form": new_order_id,
                                "productIDInput": int(r["Product ID"]),
                                "quantityInput": int(r["Quantity"]),
                            },
                        )

                st.success(f"Created Order {new_order_id}")
                st.rerun()

    st.divider()
    st.subheader("Delete Order")
    st.write("Delete an existing order and all associated line items.")

    if orders_df.empty:
        st.write("No orders to delete.")
    else:
        order_options = orders_df.index.tolist()
        selected_order_idx = st.selectbox(
            "Order",
            order_options,
            format_func=format_order_option,
            key="delete_order_select",
        )
        selected_order_id = int(orders_df.loc[selected_order_idx, "Order ID"])

        if st.button("Delete Order"):
            with engine.begin() as conn:
                conn.execute(
                    text(delete_order_query),
                    {"orderID_selected_from_browse_orders_page": selected_order_id},
                )
            st.rerun()
