import pandas as pd
import streamlit as st
from sqlalchemy import text
from db import get_engine
from reset_button import render_reset_button

st.set_page_config(page_title="Reptile Central - Animals", page_icon="👤", layout="wide")
st.title("Animals")

engine = get_engine()
render_reset_button(engine, key='reset_db_button')

animals_query = """
SELECT Animals.animalID AS "Animal ID",
       Animals.name AS "Name",
       Animals.species AS "Species",
       Animals.age AS "Age",
       Animals.price AS "Price",
       CASE WHEN Animals.isAvailable = 1 THEN 'Yes' ELSE 'No' END AS "Available",
       Animals.orderID AS "Order ID"
FROM Animals
ORDER BY Animals.animalID;
"""

insert_query = """
INSERT INTO Animals (name, species, age, price, isAvailable, orderID)
VALUES (:nameInput, :speciesInput, :ageInput, :priceInput, :isAvailableInput, NULL)
"""

update_query = """
UPDATE Animals
SET Animals.age = :ageInput,
    Animals.price = :priceInput,
    Animals.isAvailable = :isAvailableInput
WHERE Animals.animalID = :animalID_from_update_animal_form;
"""

delete_query = """
DELETE FROM Animals
WHERE Animals.animalID = :animalID_selected_from_browse_animals_page;
"""

employee_animals_query = """
SELECT EmployeeAnimals.animalDetailsID AS "Assignment ID",
       Animals.name AS "Animal Name",
       CONCAT(Employees.firstName, ' ', Employees.lastName) AS "Employee Name",
       Employees.jobTitle AS "Job Title"
FROM EmployeeAnimals
JOIN Animals ON EmployeeAnimals.animalID = Animals.animalID
JOIN Employees ON EmployeeAnimals.employeeID = Employees.employeeID
ORDER BY EmployeeAnimals.animalDetailsID;
"""

# Load animals once per run
df = pd.read_sql(animals_query, engine)

# Build picker using aliased column names
if not df.empty:
    picker_df = df[["Animal ID", "Name", "Species", "Age", "Price", "Available"]].copy()
    picker_df["Display Name"] = (
        picker_df["Name"].fillna("")
    ).str.strip()
else:
    picker_df = df

# Tabs
tab_browse, tab_create, tab_update, tab_delete, tab_assignments = st.tabs(
    ["Browse Animals", "Create Animal", "Update Animal", "Delete Animal", "Employee Assignments"]
)

# Browse Animals
with tab_browse:
    st.subheader("Browse Animals")
    st.dataframe(df, use_container_width=True, hide_index=True)

# Create Animal
with tab_create:
    st.subheader("Create Animal")
    
    with st.form("create_animal", clear_on_submit=True):
        name = st.text_input("Name")
        species = st.text_input("Species")
        age = st.text_input("Age")
        price = st.text_input("Price")
        available = st.selectbox("Available", ["Yes", "No"])
        submitted = st.form_submit_button("Create Animal")

    if submitted:
        available_value = 1 if available == "Yes" else 0
        with engine.begin() as conn:
            conn.execute(
                text(insert_query),
                {
                    "nameInput": name,
                    "ageInput": age,
                    "speciesInput": species,
                    "priceInput": price,
                    "isAvailableInput": available_value,
                },
            )
        st.rerun()

with tab_update:
    st.subheader("Update Animal")

    if df.empty:
        st.write("No animals found.")
    else:
        selected_name = st.selectbox(
            "Select Animal",
            picker_df["Display Name"].tolist(),
            key="update_animal"
        )

        selected_id = int(
            picker_df.loc[picker_df["Display Name"] == selected_name, "Animal ID"].iloc[0]
        )
        selected_age = picker_df.loc[picker_df["Display Name"] == selected_name, "Age"].iloc[0]
        selected_price = picker_df.loc[picker_df["Display Name"] == selected_name, "Price"].iloc[0]
        selected_available = picker_df.loc[picker_df["Display Name"] == selected_name, "Available"].iloc[0]

        age = st.text_input("Age", value=str(selected_age))
        price = st.text_input("Price", value=str(selected_price))
        available = st.selectbox("Available", ["Yes", "No"], index=0 if selected_available == "Yes" else 1)
        
        if st.button("Update Animal"):
            available_value = 1 if available == "Yes" else 0
            with engine.begin() as conn:
                conn.execute(
                    text(update_query),
                    {
                        "ageInput": age,
                        "priceInput": price,
                        "isAvailableInput": available_value,
                        "animalID_from_update_animal_form": selected_id,
                    },
                )
            st.rerun()

with tab_delete:
    st.subheader("Delete Animal")

    if df.empty:
        st.write("No animals to delete.")
    else:
        selected_name = st.selectbox(
            "Select Animal",
            picker_df["Display Name"].tolist(),
            key="delete_animal"
        )

        selected_id = int(
            picker_df.loc[picker_df["Display Name"] == selected_name, "Animal ID"].iloc[0]
        )

        if st.button("Delete Animal"):
            with engine.begin() as conn:
                conn.execute(
                    text(delete_query),
                    {"animalID_selected_from_browse_animals_page": selected_id},
                )
            st.rerun()

with tab_assignments:
    st.subheader("Employee Assignments")
    
    assignment_df = pd.read_sql(employee_animals_query, engine)
    if not assignment_df.empty:
        st.dataframe(assignment_df, use_container_width=True, hide_index=True)
    else:
        st.write("No assignments found.")
