import pandas as pd
import streamlit as st
from sqlalchemy import text
from db import get_engine

st.set_page_config(page_title="Reptile Central - Employees", page_icon="👤", layout="wide")
st.title("Employees")

engine = get_engine()

employees_query = """
SELECT Employees.employeeID AS "Employee ID",
       Employees.firstName AS "First Name",
       Employees.lastName AS "Last Name",
       Employees.jobTitle AS "Job Title"
FROM Employees
ORDER BY Employees.employeeID;
"""

delete_query = """
DELETE FROM Employees
WHERE Employees.employeeID = :employeeID_selected_from_browse_employees_page;
"""

insert_query = """
INSERT INTO Employees (firstName, lastName, jobTitle)
VALUES (:firstNameInput, :lastNameInput, :jobTitleInput);
"""

# Load employees once per run
df = pd.read_sql(employees_query, engine)

if not df.empty:
    picker_df = df[["Employee ID", "First Name", "Last Name", "Job Title"]].copy()
    picker_df["Display Name"] = (
        picker_df["First Name"].fillna("") + " " +
        picker_df["Last Name"].fillna("")
    ).str.strip()
else:
    picker_df = df

# Tabs
tab_browse, tab_create, tab_delete, = st.tabs(
    ["Browse Employees", "Create Employee", "Delete Employee"]
)

# Browse Employees
with tab_browse:
    st.subheader("Browse Employees")
    st.dataframe(df, use_container_width=True, hide_index=True)

# Create Employee
with tab_create:
    st.subheader("Create Employee")

    with st.form("create_employee", clear_on_submit=True):
        first = st.text_input("First Name")
        last = st.text_input("Last Name")
        job = st.text_input("Job Title")
        submitted = st.form_submit_button("Create Employee")

    if submitted:
        with engine.begin() as conn:
            conn.execute(
                text(insert_query),
                {
                    "firstNameInput": first,
                    "lastNameInput": last,
                    "jobTitleInput": job,
                },
            )
        st.rerun()

# Delete Employee
with tab_delete:
    st.subheader("Delete Employee")
    
    if df.empty:
        st.write("No employees to delete.")
    else:
        selected_name = st.selectbox(
            "Select Employee",
            picker_df["Display Name"].tolist(),
            key = "delete_employee"
        )

        selected_id = int(
            picker_df.loc[picker_df["Display Name"] == selected_name, "Employee ID"].iloc[0]
        )

        if st.button("Delete Employee"):
            with engine.begin() as conn:
                conn.execute(
                    text(delete_query),
                    {"employeeID_selected_from_browse_employees_page": selected_id},
                )
            st.rerun()