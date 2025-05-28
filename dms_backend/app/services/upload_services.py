import os
import uuid
import json
from datetime import datetime
from werkzeug.utils import secure_filename
from database import get_db_connection, get_db_cursor, close_db_connection
import mysql.connector
import jwt
from flask import request

# Constants
BASE_UPLOAD_FOLDER = "uploads/bioclaim/documents"
JWT_SECRET_KEY = "your-secret-key"  # Replace with your actual secret key
JWT_ALGORITHM = "HS256"

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
        decoded_token = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
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

def handle_file_upload(file, metadata_str, user_id):
    conn = None
    cursor = None
    file_path_on_disk = None

    # 🔐 Decode JWT
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
