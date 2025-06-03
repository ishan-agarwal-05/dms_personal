from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token
from app.database import get_db_connection, get_db_cursor, close_db_connection
import bcrypt

auth_bp = Blueprint('auth_routes', __name__)

@auth_bp.route('/login', methods=['POST'])
def login():
    """
    Handles user login, authenticates credentials, and issues a JWT.
    """
    username = request.json.get("username")
    password = request.json.get("password")

    if not username or not password:
        return jsonify({"msg": "Missing username or password"}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"msg": "Database connection error"}), 500
        cursor = get_db_cursor(conn)
        
        # Query ds_user table to get the hashed password, user_id, and username
        select_query = "SELECT id, username, password, first_name FROM ds_user WHERE username = %s AND deleted = 0 AND status = 'active'"
        cursor.execute(select_query, (username,))
        user_record = cursor.fetchone()

        if user_record:
            stored_hashed_password = user_record['password']
            user_id = user_record['id']
            user_username = user_record['username']
            first_name = user_record['first_name']

            # Verify the provided password against the stored hash
            if bcrypt.checkpw(password.encode('utf-8'), stored_hashed_password.encode('utf-8')):
                # Credentials are valid, create and return JWT
                access_token = create_access_token(
                    identity=username, # The identity usually is something unique like username
                    additional_claims={"user_id": user_id, "username": user_username, "first_name": first_name}
                )
                return jsonify(access_token=access_token), 200
            else:
                return jsonify({"msg": "Bad username or password"}), 401
        else:
            return jsonify({"msg": "Bad username or password"}), 401

    except Exception as e:
        print(f"ERROR: Login failed due to unexpected error: {e}")
        return jsonify({"msg": "An internal error occurred during login"}), 500
    finally:
        close_db_connection(conn, cursor)