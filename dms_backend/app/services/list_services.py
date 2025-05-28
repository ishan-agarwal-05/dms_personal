from database import get_db_connection, get_db_cursor, close_db_connection
from datetime import datetime
import mysql.connector

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