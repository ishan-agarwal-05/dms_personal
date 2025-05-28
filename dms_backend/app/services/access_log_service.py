import json
from datetime import datetime, timezone
from database import get_db_connection, get_db_cursor, close_db_connection
from flask import request

def log_api_access(url, method, request_body, response, status, ip, env_id=None, created_by=1):
    """
    Logs API access details to the ds_access_log table in the database.

    Args:
        url (str): The URL of the API endpoint accessed.
        method (str): The HTTP method (e.g., 'POST', 'GET', 'DELETE').
        request_body (dict/str): The request body (will be converted to JSON string).
        response (dict/str): The response body (will be converted to JSON string).
        status (str): The status of the operation ('Requested', 'Failed', 'Success').
        ip (str): The IP address of the client.
        env_id (int, optional): The environment ID, if available. Defaults to None.
        created_by (int, optional): The ID of the user who initiated the request. Defaults to 1.
    """
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            print("ERROR: Failed to connect to database for access logging.")
            return False

        cursor = get_db_cursor(conn)

        # Current timestamp
        now = datetime.now(timezone.utc)

        insert_query = """
            INSERT INTO ds_access_log
            (env_id, url, method, request_body, response, status, ip, createdAt, createdBy)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        # Ensure request_body and response are strings for DB insertion
        request_body_str = json.dumps(request_body) if isinstance(request_body, (dict, list)) else str(request_body)
        response_str = json.dumps(response) if isinstance(response, (dict, list)) else str(response)

        log_data = (
            env_id,
            url,
            method,
            request_body_str,
            response_str,
            status,
            ip,
            datetime.utcnow(),
            created_by
        )
        cursor.execute(insert_query, log_data)
        conn.commit()

    except Exception as e:
        if conn:
            conn.rollback()
        print(f"ERROR: Error logging API access to database: {e}")
    finally:
        close_db_connection(conn, cursor)


def log_api_operation(claims, request_context, response_data, request_body_log, log_env_id):
    """
    Consolidates the logic for logging API operations.
    """
    log_user_id = claims.get("user_id")
    request_url = request_context["url"]
    request_method = request_context["method"]
    request_ip = request_context["ip"]

    # Determine logging status
    log_status = 'Success' if response_data.get("responseCode") == 200 else 'Failed'

    # Log the operation to ds_access_log
    log_api_access(
        url=request_url,
        method=request_method,
        request_body=request_body_log,
        response=response_data,
        status=log_status,
        ip=request_ip,
        env_id=log_env_id,
        created_by=log_user_id
    )