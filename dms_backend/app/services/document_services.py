import os
import uuid
import json
from datetime import datetime, timezone
from werkzeug.utils import secure_filename
from app.database import get_db_connection, get_db_cursor, close_db_connection
import mysql.connector
import jwt
from flask import current_app, request

# Constants
BASE_UPLOAD_FOLDER = "uploads/bioclaim/documents"

# --- Logging Functions (Moved from access_log_service.py) ---

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
    
# --- End Logging Functions ---

# --- Document Services ---

# --- File Upload and Handling Functions ---

def allowed_file(filename, allowed_extensions_set):
    if '.' not in filename:
        return False
    file_ext = filename.rsplit('.', 1)[1].lower()
    return file_ext in allowed_extensions_set

def decode_jwt_from_request():
    """
    Extracts and decodes the JWT token from the Authorization header.
    """
    auth_header = request.headers.get("Authorization", None)
    if not auth_header or not auth_header.startswith("Bearer "):
        return None, {
            "responseCode": 401,
            "responseStatus": "error",
            "responseMessage": "Missing or invalid Authorization header."
        }

    token = auth_header.split(" ")[1]
    try:
        secret_key = current_app.config.get("JWT_SECRET_KEY")
        algorithm = current_app.config.get("JWT_ALGORITHM", "HS256")
        
        if not secret_key:
            raise ValueError("JWT_SECRET_KEY not configured in Flask app.")
        
        decoded_token = jwt.decode(token, secret_key, algorithms=[algorithm])
        return decoded_token, None
    except jwt.ExpiredSignatureError:
        return None, {
            "responseCode": 401,
            "responseStatus": "error",
            "responseMessage": "Token has expired."
        }
    except jwt.InvalidTokenError:
        return None, {
            "responseCode": 401,
            "responseStatus": "error",
            "responseMessage": "Invalid token."
        }
    except ValueError as e:
        return None, {
            "responseCode": 500,
            "responseStatus": "error",
            "responseMessage": f"Server configuration error: {str(e)}"
        }

def handle_file_upload(file, metadata_str, user_id):
    conn = None
    cursor = None
    file_path_on_disk = None

    decoded_token, token_error = decode_jwt_from_request()
    if token_error:
        return token_error

    user_id = decoded_token.get("user_id")
    if not user_id:
        return {
            "responseCode": 401,
            "responseStatus": "error",
            "responseMessage": "Unauthorized. 'user_id' not found in token."
        }

    try:
        metadata = json.loads(metadata_str)
    except json.JSONDecodeError:
        return {
            "responseCode": 400,
            "responseStatus": "error",
            "responseMessage": "Invalid JSON format in 'data'."
        }

    file_type = metadata.get("method")
    module_id = metadata.get("module")
    env_id = metadata.get("application_id")
    ref_id = metadata.get("reference_id")
    parent_id = metadata.get("parent_id")

    if not all([file_type, module_id, env_id, ref_id]):
        return {
            "responseCode": 400,
            "responseStatus": "error",
            "responseMessage": "Missing required metadata fields: method, module, application_id, or reference_id."
        }

    conn = get_db_connection()
    if not conn:
        return {
            "responseCode": 500,
            "responseStatus": "error",
            "responseMessage": "Failed to connect to the database."
        }
    cursor = get_db_cursor(conn)

    try:
        query_master = """
            SELECT allowed_extension, allowed_max_size, filepath
            FROM ds_document_master
            WHERE env_id = %s AND module_id = %s AND type = %s AND deleted = 0 AND status = 'active'
        """
        cursor.execute(query_master, (env_id, module_id, file_type))
        doc_master_config = cursor.fetchone()

        if not doc_master_config:
            return {
                "responseCode": 404,
                "responseStatus": "error",
                "responseMessage": f"No document master configuration found for type '{file_type}' in module '{module_id}' and environment '{env_id}'."
            }

        raw_allowed_extensions = doc_master_config['allowed_extension']
        parsed_extensions = set()

        try:
            temp_list = json.loads(raw_allowed_extensions.replace("'", '"'))
            if not isinstance(temp_list, list):
                raise ValueError("allowed_extension is not a JSON list.")
            for ext in temp_list:
                clean_ext = str(ext).strip().lstrip('.').lower()
                if clean_ext:
                    parsed_extensions.add(clean_ext)
        except (json.JSONDecodeError, ValueError) as e:
            return {
                "responseCode": 500,
                "responseStatus": "error",
                "responseMessage": f"Invalid format for 'allowed_extension'. Error: {e}"
            }

        if not parsed_extensions:
            return {
                "responseCode": 500,
                "responseStatus": "error",
                "responseMessage": "Allowed_extension configuration is empty or invalid after parsing."
            }

        max_file_size_kb = doc_master_config['allowed_max_size']
        max_file_size_bytes = max_file_size_kb * 1024

        if not allowed_file(file.filename, parsed_extensions):
            return {
                "responseCode": 400,
                "responseStatus": "error",
                "responseMessage": f"File type not allowed. Allowed types: {', '.join(sorted(list(parsed_extensions)))}"
            }

        if file.content_length > max_file_size_bytes:
            return {
                "responseCode": 400,
                "responseStatus": "error",
                "responseMessage": f"File size exceeds the maximum allowed size of {max_file_size_kb} KB."
            }

        file_ext = file.filename.rsplit('.', 1)[1].lower()
        original_filename = secure_filename(file.filename)
        unique_filename = f"{file_type}_{str(uuid.uuid4())}.{file_ext}"

        today = datetime.today()
        base_upload_path = doc_master_config['filepath'].rstrip('/') if doc_master_config['filepath'] else BASE_UPLOAD_FOLDER
        dynamic_path = os.path.join(
            base_upload_path,
            today.strftime("%Y"),
            today.strftime("%m"),
            today.strftime("%d")
        )

        os.makedirs(dynamic_path, exist_ok=True)
        file_path_on_disk = os.path.join(dynamic_path, unique_filename)
        file.save(file_path_on_disk)

        insert_query = """
            INSERT INTO ds_document
            (env_id, parent_id, ref_id, module_id, type, filename, original_filename, filepath, filesize, extension, createdBy, createdAt)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        document_data = (
            env_id,
            parent_id,
            ref_id,
            module_id,
            file_type,
            unique_filename,
            original_filename,
            file_path_on_disk.replace("\\", "/"),
            file.content_length,
            file_ext,
            user_id,
            datetime.utcnow()
        )
        cursor.execute(insert_query, document_data)
        conn.commit()
        document_id = cursor.lastrowid

        return {
            "responseCode": 200,
            "responseStatus": "success",
            "responseMessage": "Document uploaded successfully",
            "responseData": {
                "id": document_id,
                "type": file_type,
                "name": original_filename,
                "path": file_path_on_disk.replace("\\", "/"),
                "fileName": unique_filename
            },
            "fileName": original_filename
        }

    except mysql.connector.Error as e:
        conn.rollback()
        if file_path_on_disk and os.path.exists(file_path_on_disk):
            os.remove(file_path_on_disk)
        print(f"Database error: {e}")
        return {
            "responseCode": 500,
            "responseStatus": "error",
            "responseMessage": f"Failed to store document metadata: {str(e)}"
        }
    except Exception as e:
        if conn:
            conn.rollback()
        if file_path_on_disk and os.path.exists(file_path_on_disk):
            os.remove(file_path_on_disk)
        print(f"Unexpected error: {e}")
        return {
            "responseCode": 500,
            "responseStatus": "error",
            "responseMessage": f"Unexpected error: {str(e)}"
        }
    finally:
        close_db_connection(conn, cursor)

# --- List and Delete Document Services ---

def list_documents_service(data, user_id):
    """
    Retrieves document metadata from the database using direct SQL queries.
    Optionally uses user_id for internal authorization checks.
    """
    module = data.get("module")
    application_id = data.get("application_id")
    reference_id = data.get("reference_id")

    if not all([module, application_id, reference_id]):
        return {
            "responseCode": 400,
            "responseStatus": "fail",
            "responseMessage": "Missing required fields: module, application_id, or reference_id",
            "responseData": []
        }

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            return {
                "responseCode": 500,
                "responseStatus": "error",
                "responseMessage": "Failed to connect to the database."
            }
        cursor = get_db_cursor(conn)

        # Query the ds_document table using direct SQL
        query = """
            SELECT id, ref_id, type, original_filename, filename, filepath, filesize, extension, createdAt, status
            FROM ds_document
            WHERE module_id = %s AND env_id = %s AND ref_id = %s AND deleted = 0
        """
        cursor.execute(query, (module, application_id, reference_id))
        documents = cursor.fetchall() # Fetch all results as dictionaries

        # Format the results for the API response
        response_data = []
        for doc in documents:
            response_data.append({
                "id": doc['id'],
                "ref_id": doc['ref_id'],
                "type": doc['type'],
                "original_filename": doc['original_filename'],
                "filename": doc['filename'],
                "filepath": doc['filepath'],
                "filesize": doc['filesize'],
                "extension": doc['extension'],
                "createdAt": doc['createdAt'].isoformat() if isinstance(doc['createdAt'], datetime) else str(doc['createdAt']),
                "status": doc['status']
            })

        return {
            "responseCode": 200,
            "responseStatus": "success",
            "responseMessage": "Documents retrieved successfully",
            "responseData": response_data
        }
    except mysql.connector.Error as e:
        print(f"Database error during document retrieval: {e}")
        return {
            "responseCode": 500,
            "responseStatus": "error",
            "responseMessage": f"Failed to retrieve documents: {str(e)}",
            "responseData": []
        }
    except Exception as e:
        print(f"An unexpected error occurred during document retrieval: {e}")
        return {
            "responseCode": 500,
            "responseStatus": "error",
            "responseMessage": f"An unexpected error occurred: {str(e)}",
            "responseData": []
        }
    finally:
        close_db_connection(conn, cursor)
        
def delete_document_service(data, user_id):
    """
    Deletes a document by marking it as deleted in the database
    and physically removing the file from disk.

    Args:
        data (dict): A dictionary containing document identification details.
                     Expected keys: "id", "module", "application_id", "reference_id".
        user_id (int): The ID of the user performing the deletion, obtained from JWT.
    """
    id = data.get("id")
    module_id = data.get("module")
    env_id = data.get("application_id")
    ref_id = data.get("reference_id")
    filepath = data.get("filepath")
    
    if not all([id, module_id, env_id, ref_id, filepath]):
        return {
            "responseCode": 400,
            "responseStatus": "error",
            "responseMessage": "Missing required fields: id, module, application_id, reference_id, or filepath."
        }
   
    conn = get_db_connection()
    if not conn:
        return {
            "responseCode": 500,
            "responseStatus": "error",
            "responseMessage": "Failed to connect to the database."
        }
    
    cursor = get_db_cursor(conn)
    
    try:
        select_query = """
            SELECT id, filepath
            FROM ds_document
            WHERE id = %s AND module_id = %s AND env_id = %s AND ref_id = %s AND deleted = 0        
        """
        
        cursor.execute(select_query, (id, module_id, env_id, ref_id))
        document = cursor.fetchone()
        
        if not document:
            return {
                "responseCode": 404, # Use 404 for not found, 400 for bad request
                "responseStatus": "error",
                "responseMessage": "Document not found or already deleted."
            }
        
        file_path_from_db = document['filepath']
        file_path_on_disk = file_path_from_db.replace("\\", "/")

        if os.path.exists(file_path_on_disk):
            os.remove(file_path_on_disk)
        
        update_query = """
            UPDATE ds_document
            SET deleted = 1, updatedBy = %s, updatedAt = NOW()
            WHERE id = %s
        """
        cursor.execute(update_query, (user_id, id))
        conn.commit()
                
        return {
            "responseCode": 200,
            "responseStatus": "success",
            "responseMessage": "Document has been deleted successfully"
        }
        
    except mysql.connector.Error as e:
        conn.rollback() # Rollback any database changes on error
        print(f"ERROR: Database error during deletion for ID={id}: {str(e)}")
        return {
            "responseCode": 500,
            "responseStatus": "error",
            "responseMessage": f"Database error during deletion: {str(e)}"
        }
    except Exception as e:
        print(f"CRITICAL: Unexpected error during deletion for ID={id}: {str(e)}")
        return {
            "responseCode": 500,
            "responseStatus": "error",
            "responseMessage": f"Unexpected error during deletion: {str(e)}"
        }
    finally:
        close_db_connection(conn, cursor)

