import os
from database import get_db_connection, get_db_cursor, close_db_connection
from datetime import datetime
import mysql.connector

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
