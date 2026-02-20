import streamlit as st
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError


def render_reset_button(engine, key: str) -> None:
    st.sidebar.markdown(
        """
<style>
section[data-testid="stSidebar"] div.stButton > button[kind="primary"] {
    background-color: #dc2626 !important;
    color: #ffffff !important;
    border: 1px solid #b91c1c !important;
}
section[data-testid="stSidebar"] div.stButton > button[kind="primary"]:hover {
    background-color: #b91c1c !important;
    color: #ffffff !important;
    border: 1px solid #991b1b !important;
}
section[data-testid="stSidebar"] div.stButton > button[kind="primary"]:focus {
    box-shadow: 0 0 0 0.2rem rgba(220, 38, 38, 0.35) !important;
}
</style>
        """,
        unsafe_allow_html=True,
    )

    if st.sidebar.button("Reset Database", key=key, type="primary"):
        try:
            with engine.begin() as conn:
                conn.execute(text("CALL sp_reset_database();"))
            st.sidebar.success("Database reset complete.")
            st.rerun()
        except SQLAlchemyError as exc:
            st.sidebar.error(f"Reset failed: {exc}")
