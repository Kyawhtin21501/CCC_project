# app.py (PostgreSQL version)
import os
import sys
import logging
from datetime import date, timedelta, datetime
import pandas as pd
from flask import Flask, request, jsonify
from flask_cors import CORS
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
from pprint import pprint

# Load env
load_dotenv()

# Logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

# Database
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+psycopg2://khein21502:@localhost/ccc_project")
engine = create_engine(DATABASE_URL)

# Project paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Services (keep using your existing services if needed)
from services.staff_manager import StaffManager
from services.user_input_handler import UserInputHandler
from services.pred import ShiftCreator
from services.shifting_operator import ShiftOperator
from services.shift_preferences import ShiftPreferences

app = Flask(__name__)
CORS(app)  # allow from all origins (restrict in production)

staff_manager = StaffManager()  # uses DB inside as we designed

# -------------------------
# Health check
# -------------------------
@app.route('/')
def home():
    return "API Server is Running"

# -------------------------
# staff_list (existing route name)
# -------------------------
@app.route('/staff_list', methods=['GET'])
def staff_list():
    try:
        df = pd.read_sql("SELECT * FROM staff_profile", engine)
        # handle possible column name variations
        if "name" in df.columns:
            names = df["name"].dropna().unique().tolist()
        elif "Name" in df.columns:
            names = df["Name"].dropna().unique().tolist()
        else:
            return jsonify({"error": "No 'name' column found in staff_profile"}), 500
        return jsonify(names)
    except Exception as e:
        logging.exception("Failed to load staff_list")
        return jsonify({"error": str(e)}), 500

# -------------------------
# Create staff (matches original /services/staff POST)
# -------------------------
@app.route('/services/staff', methods=['POST'])
def create_staff():
    try:
        data = request.get_json(force=True)
        logging.info(f"Create staff request: {data}")

        # Basic validation
        required = ["Name", "Level", "Gender", "Age", "Email"]
        missing = [k for k in required if k not in data]
        if missing:
            return jsonify({"error": f"Missing fields: {missing}"}), 400
        
        # Clean / normalize
        name = data["Name"].strip()
        level = int(data["Level"])
        gender = data["Gender"]
        age = int(data["Age"])
        email = data["Email"]
        status = data.get("status") or data.get("Status") or ""

        # Upsert into staff_profile
        query = text("""
            INSERT INTO staff_profile (name, level, gender, age, email, status)
            VALUES (:name, :level, :gender, :age, :email, :status)
            RETURNING id, name
        """)
        with engine.begin() as conn:
            res = conn.execute(query, {
                "name": name, "level": level, "gender": gender,
                "age": age, "email": email, "status": status
            })
            row = res.fetchone()
            # If your table uses different column names, adjust accordingly.

        return jsonify({"message": "Staff created", "staff": {"id": row[0], "name": row[1]}}), 200

    except Exception as e:
        logging.exception("Failed to create staff")
        return jsonify({"error": str(e)}), 400

# -------------------------
# Update / Get staff by ID (matches original route and methods)
# PUT: update, GET/POST: get info
# -------------------------
@app.route('/services/staff/<int:staff_id>', methods=['PUT', 'GET', 'POST'])
def update_staff_by_id(staff_id):
    try:
        if request.method == 'PUT':
            if not request.is_json:
                return jsonify({"error": "Content-Type must be application/json"}), 415
            updates = request.get_json(silent=True) or {}
            if not isinstance(updates, dict) or not updates:
                return jsonify({"error": "Request body must be a non-empty JSON object"}), 400
            if 'ID' in updates or 'id' in updates:
                return jsonify({"error": "ID cannot be updated"}), 400

            # Build update SQL dynamically but safely
            allowed = {"Name", "Level", "Gender", "Age", "Email", "status", "name", "level"}
            set_parts = []
            params = {"staff_id": staff_id}
            for k, v in updates.items():
                if k not in allowed:
                    continue
                col = k.lower() if k[0].isupper() else k
                param_name = f"p_{col}"
                set_parts.append(f"{col} = :{param_name}")
                params[param_name] = v

            if not set_parts:
                return jsonify({"error": "No valid fields to update"}), 400

            query = text(f"UPDATE staff_profile SET {', '.join(set_parts)} WHERE id = :staff_id RETURNING id")
            with engine.begin() as conn:
                res = conn.execute(query, params)
                updated = res.fetchone()
                if not updated:
                    return jsonify({"error": "Staff ID not found or no update made"}), 404

            return jsonify({"message": f"Staff {staff_id} updated successfully"}), 200

        else:
            # GET or POST -> fetch staff info by id
            query = text("SELECT * FROM staff_profile WHERE id = :staff_id")
            df = pd.read_sql_query(query, engine, params={"staff_id": staff_id})
            if df.empty:
                return jsonify({"error": "Staff not found"}), 404
            # convert row to dict
            record = df.iloc[0].to_dict()
            # normalize keys for frontend if needed (keep original casing)
            return jsonify(record), 200

    except Exception as e:
        logging.exception("Update/Get staff failed")
        return jsonify({'error': str(e)}), 500

# -------------------------
# Delete staff (matches original /services/staff/<id> DELETE)
# -------------------------
@app.route('/services/staff/<int:staff_id>', methods=['DELETE'])
def delete_staff(staff_id):
    try:
        # Remove staff from staff_profile and related schedules (transactional)
        with engine.begin() as conn:
            # Delete from staff_schedule (or staff_shift) where staff id referenced
            # adjust column names depending on your schema
            conn.execute(text("DELETE FROM staff_schedule WHERE id = :staff_id"), {"staff_id": staff_id})
            res = conn.execute(text("DELETE FROM staff_profile WHERE id = :staff_id RETURNING id"), {"staff_id": staff_id})
            deleted = res.fetchone()
            if not deleted:
                return jsonify({"error": "Staff not found"}), 404

        return jsonify({"message": f"Staff {staff_id} deleted successfully"}), 200

    except Exception as e:
        logging.exception("Delete staff failed")
        return jsonify({"error": str(e)}), 400

# -------------------------
# Search staff (matches original route)
# GET ?term=... & ?by=ID|Name
# -------------------------
@app.route('/services/staff/search', methods=['GET'])
def search_staff():
    term = request.args.get("term")
    by = request.args.get("by", "ID")
    try:
        if by.upper() == "ID":
            # ensure integer
            try:
                staff_id = int(term)
            except Exception:
                return jsonify({"error": "Invalid ID"}), 400
            df = pd.read_sql_query(text("SELECT * FROM staff_profile WHERE id = :id"), engine, params={"id": staff_id})
        else:
            # search by name (case-insensitive)
            df = pd.read_sql_query(text("SELECT * FROM staff_profile WHERE name ILIKE :name"), engine, params={"name": f"%{term}%"})

        if df.empty:
            return jsonify({"message": "Not found"}), 404
        return jsonify(df.to_dict(orient="records")), 200
    except Exception as e:
        logging.exception("Search staff failed")
        return jsonify({"error": str(e)}), 400

# -------------------------
# Save dashboard user input (/user_input)
# -------------------------
@app.route('/user_input', methods=['POST'])
def save_data():
    data = request.get_json(force=True)
    logging.info(f"Received /user_input: {data}")

    if not data:
        return jsonify({"error": "No data provided"}), 400

    required_columns = ("date", "event", "sales", "customer_count", "staff_count")
    missing = [col for col in required_columns if col not in data]
    if missing:
        return jsonify({"error": f"Missing required fields: {missing}"}), 400

    # Normalize types
    try:
        # date: accept date string or date object
        if not isinstance(data["date"], (date, datetime)):
            data["date"] = date.fromisoformat(data["date"])
        # numeric fields
        data["sales"] = int(data["sales"])
        data["customer_count"] = int(data["customer_count"])
        data["staff_count"] = int(data["staff_count"])
        # event -> bool (support 1/0/"True"/True)
        ev = data["event"]
        if isinstance(ev, bool):
            data["event"] = ev
        elif isinstance(ev, (int, float)):
            data["event"] = bool(int(ev))
        else:
            data["event"] = str(ev).lower() in ("true", "1", "yes")
    except Exception as e:
        logging.exception("Validation failed")
        return jsonify({"error": f"Invalid data types: {str(e)}"}), 400

    try:
        # Clean staff names and compute any additional fields with service classes
        data["staff_names"] = staff_manager.clean_names(data.get("staff_names", []))
        save_processor = UserInputHandler(input_data=data, staff_manager=staff_manager)
        processed = save_processor.process_and_save()  # should return dict ready to save

        # Save to DB user_input table
        # Ensure processed keys map to columns: date, is_festival, sales, guests, staff_count, assigned_staff, total_staff_level (if present)
        columns = list(processed.keys())
        placeholders = ", ".join([f":{c}" for c in columns])
        colnames = ", ".join(columns)
        insert_sql = text(f"INSERT INTO user_input ({colnames}) VALUES ({placeholders})")
        with engine.begin() as conn:
            conn.execute(insert_sql, processed)

        return jsonify({"message": "Data saved successfully"}), 200

    except Exception as e:
        logging.exception("Data saving failed")
        return jsonify({"error": str(e)}), 500

# -------------------------
# Save shift preferences (/save_shift_preferences) — write into staff_schedule
# -------------------------
@app.route('/save_shift_preferences', methods=['POST'])
def save_shift_preferences():
    try:
        data = request.get_json(force=True)
        date_str = data.get("date")
        preferences = data.get("preferences")
        if not date_str or preferences is None:
            return jsonify({"error": "date and preferences required"}), 400

        # Build DataFrame from the preferences dict (keyed by staff name or id)
        df = pd.DataFrame.from_dict(preferences, orient='index').reset_index()
        df.rename(columns={'index': 'staff'}, inplace=True)
        df["date"] = date_str

        # Merge with staff_profile to attach IDs (if staff names provided)
        staff_df = pd.read_sql("SELECT id, name FROM staff_profile", engine)
        merged = df.merge(staff_df, left_on="staff", right_on="name", how="left")

        # For each row, insert or update into staff_schedule table (id, date, morning, afternoon, night)
        with engine.begin() as conn:
            # delete existing for date and same ids to avoid duplicates (simple strategy)
            unique_date = date_str
            conn.execute(text("DELETE FROM staff_schedule WHERE date = :d"), {"d": unique_date})
            # insert rows
            for _, row in merged.iterrows():
                insert = text("""
                    INSERT INTO staff_schedule (id, date, morning, afternoon, night)
                    VALUES (:id, :date, :morning, :afternoon, :night)
                """)
                params = {
                    "id": int(row["id"]) if pd.notna(row.get("id")) else None,
                    "date": row["date"],
                    "morning": bool(row.get("morning")) if "morning" in row else False,
                    "afternoon": bool(row.get("afternoon")) if "afternoon" in row else False,
                    "night": bool(row.get("night")) if "night" in row else False
                }
                # if id is None, skip or handle differently; here we skip rows without id
                if params["id"] is None:
                    logging.warning(f"Skipping preference for unknown staff: {row.get('staff')}")
                    continue
                conn.execute(insert, params)

        return jsonify({"message": "Shift preferences saved"}), 200

    except Exception as e:
        logging.exception("Save shift preferences failed")
        return jsonify({"error": str(e)}), 500

# -------------------------
# /shift endpoint: predict and assign shifts (keeps original route name)
# -------------------------
@app.route('/shift', methods=['POST', 'GET'])
def shift():
    try:
        data = request.get_json(force=True)
        start_date = data.get("start_date")
        end_date = data.get("end_date")
        if not start_date or not end_date:
            return jsonify({"error": "start_date and end_date required"}), 400

        # Use ShiftCreator (expects strings in YYYY-MM-DD)
        creator = ShiftCreator(start_date, end_date)
        start, end = creator.date_data_from_user()
        if not start or not end:
            return jsonify({"error": "Invalid date range"}), 400

        # festivals, weather
        festivals = creator.check_festival_range(start, end)
        # open-meteo expects next-day range in your earlier code; keep same behavior
        weather_df = creator.weather_data(start + timedelta(days=1), end + timedelta(days=1))

        pred_df = creator.pred_from_model(start, end, festivals, weather_df)
        result_df = creator.pred_staff_count(pred_df)  # returns DataFrame or list of dicts per earlier impl

        # Load staff schedule & profile from DB
        shift_preferences_df = pd.read_sql_table("staff_schedule", engine)
        staff_database_df = pd.read_sql_table("staff_profile", engine)
        shift_preferences_df["date"] = pd.to_datetime(shift_preferences_df["date"]).dt.date

        # Filter by requested date range
        shift_preferences_df = shift_preferences_df[(shift_preferences_df["date"] >= start) & (shift_preferences_df["date"] <= end)]

        # Run shift optimization
        # Pass required_level as DataFrame (ShiftOperator implementation should handle)
        shift_operator = ShiftOperator(
            shift_preferences=shift_preferences_df,
            staff_dataBase=staff_database_df,
            required_level=result_df
        )
        shift_schedule = shift_operator.assign_shifts()

        # Save temporary shift schedule into temporary_shift_for_dashboard table
        # Example: create rows with date, shift, name_level columns (adapt as needed)
        if not shift_schedule.empty:
            # Convert date column to datetime
            df_to_save = shift_schedule.copy()
            # Ensure columns: date, shift, id, level, name (depending on your ShiftOperator output)
            # Here we store as-is into temporary_shift_for_dashboard (adjust columns as DB schema)
            with engine.begin() as conn:
                # delete existing for date range
                conn.execute(text("DELETE FROM temporary_shift_for_dashboard WHERE date >= :start AND date <= :end"),
                             {"start": start, "end": end})
                # insert rows
                for _, row in df_to_save.iterrows():
                    insert = text("""
                        INSERT INTO temporary_shift_for_dashboard (date, shift, staff_id, staff_name, level)
                        VALUES (:date, :shift, :staff_id, :staff_name, :level)
                    """)
                    params = {
                        "date": str(row.get("date")),
                        "shift": row.get("shift"),
                        "staff_id": int(row.get("id")) if pd.notna(row.get("id")) else None,
                        "staff_name": row.get("name", None),
                        "level": int(row.get("level")) if pd.notna(row.get("level")) else None
                    }
                    conn.execute(insert, params)

        pred_df_records = pred_df.to_dict(orient="records") if isinstance(pred_df, pd.DataFrame) else pred_df
        # Return both schedule and predictions
        return jsonify({
            "shift_schedule": shift_schedule.to_dict(orient="records") if isinstance(shift_schedule, pd.DataFrame) else shift_schedule,
            "prediction": pred_df_records
        }), 200

    except Exception as e:
        logging.exception("Shift generation failed")
        return jsonify({"error": str(e)}), 500

# -------------------------
# GET shift table for dashboard (existing route)
# -------------------------
@app.route('/shift_table/dashboard', methods=['GET', 'POST'])
def get_shift_table_dashboard():
    try:
        df = pd.read_sql("SELECT * FROM temporary_shift_for_dashboard ORDER BY date ASC", engine)
        return jsonify(df.to_dict(orient="records")), 200
    except Exception as e:
        logging.exception("Failed to fetch temporary shift table")
        return jsonify({"error": str(e)}), 500

# -------------------------
# GET predicted sales for dashboard (existing route)
# -------------------------
@app.route('/pred_sale/dashboard', methods=['GET', 'POST'])
def get_pred_sale_dashboard():
    try:
        df = pd.read_sql("SELECT * FROM predicted_sales ORDER BY date ASC", engine)
        return jsonify(df.to_dict(orient="records")), 200
    except Exception as e:
        logging.exception("Failed to fetch predicted sales")
        return jsonify({"error": str(e)}), 500

# -------------------------
# Staff search helper that mirrors older CSV-based SearchStaff route (keeps original name)
# -------------------------
@app.route('/services/staff/search_csv_compat', methods=['GET'])
def search_staff_csv_compat():
    """
    Optional backward-compatible route if something relies on CSV-style search.
    Still reads from DB.
    """
    term = request.args.get("term")
    by = request.args.get("by", "ID")
    try:
        if by.upper() == "ID":
            df = pd.read_sql_query(text("SELECT * FROM staff_profile WHERE id = :id"), engine, params={"id": int(term)})
        else:
            df = pd.read_sql_query(text("SELECT * FROM staff_profile WHERE name ILIKE :name"), engine, params={"name": f"%{term}%"})
        if df.empty:
            return jsonify("error"), 404
        return jsonify(df.to_dict(orient="records")), 200
    except Exception as e:
        logging.exception("CSV compatibility search failed")
        return jsonify({"error": str(e)}), 500

# -------------------------
# Main
# -------------------------
if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
