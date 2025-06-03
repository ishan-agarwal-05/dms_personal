from app.database import get_db_connection
from flask import jsonify
from app.database import get_db_connection, close_db_connection
from flask import jsonify, request
from mysql.connector import Error
from typing import Union, List, Tuple, Optional
import json # Import json for response data

def get_entity_details(data, id_field, table_name, not_found_message="Entity not found"):
    """
    Generic function to fetch entity details from database
    
    Args:
        data (dict): Request data containing the ID
        id_field (str): The name of the ID field in the request data
        table_name (str): Database table to query
        not_found_message (str): Custom message for when entity isn't found
        
    Returns:
        tuple: (response, status_code)
    """
    if not data or id_field not in data:
        return jsonify({'message': f'{id_field} is required in request body'}), 400

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(f"SELECT * FROM {table_name} WHERE id = %s", (data[id_field],))
    entity = cursor.fetchone()
    cursor.close()
    conn.close()

    if entity:
        return jsonify(entity), 200
    else:
        return jsonify({'message': not_found_message}), 404

# Now refactor the existing functions to use the generic function
def get_access_log_details(data):
    return get_entity_details(
        data, 
        'access_log_id', 
        'ds_access_log', 
        'Log not found'
    )
    
def get_app_config_details(data):
    return get_entity_details(
        data, 
        'app_config_id', 
        'ds_application_config', 
        'Application not found'
    )

def get_ds_master_details(data):
    return get_entity_details(
        data, 
        'ds_master_id', 
        'ds_document_master', 
        'Not found'
    )

def get_upload_detail_services(data):
    return get_entity_details(
        data, 
        'upload_id', 
        'ds_document', 
        'File details not found'
    )
    
def get_user_details(data):
    return get_entity_details(
        data, 
        'user_id', 
        'ds_user', 
        'User not found'
    )


# Default items per page for pagination
DEFAULT_ITEMS_PER_PAGE = 5

def get_request_data():
    """
    Helper function to safely get JSON data from the request body.
    Handles cases where no JSON data is provided or an error occurs during parsing.

    Returns:
        tuple: (request_data, error_response, status_code)
               - request_data (dict or None): The parsed JSON data if successful.
               - error_response (dict or None): An error message dictionary if an error occurred.
               - status_code (int or None): The HTTP status code associated with the error.
    """
    try:
        request_data = request.get_json()
        if not request_data:
            return None, {"error": "Request body must be JSON"}, 400
        return request_data, None, None
    except Exception as e:
        print(f"An unexpected error occurred in get_request_data: {e}")
        return None, {"error": "Internal server error"}, 500

def send_response(data: Union[List[Tuple], Tuple, None], page: int, limit: int, total_items: int, total_pages: int):
    """
    Helper function to standardize the JSON response for list endpoints,
    including pagination metadata.

    Args:
        data (Union[List[Tuple], Tuple, None]): The list of data records.
        page (int): The current page number.
        limit (int): The number of items per page.
        total_items (int): The total number of items available.
        total_pages (int): The total number of pages.

    Returns:
        tuple: (response, status_code)
               - response (flask.Response): JSON response object.
               - status_code (int): HTTP status code (200 for success).
    """
    response = {
        "data": data,
        "currentPage": page,
        "itemsPerPage": limit,
        "totalItems": total_items,
        "totalPages": total_pages
    }
    return jsonify(response), 200

def execute_query(query: str, params: Optional[Union[tuple, list]] = None, fetch_one: bool = False):
    """
    Executes a SQL query and returns the results.
    Handles connection opening and closing for each query.
    This version is optimized for read-only operations (SELECT statements).

    Args:
        query (str): The SQL query string to execute.
        params (Optional[Union[tuple, list]]): Parameters to be safely passed to the query.
        fetch_one (bool): If True, fetches only one row; otherwise, fetches all rows.

    Returns:
        Union[dict, list, None]: Query result (dictionary for single row, list of dictionaries for multiple rows,
                                      or None on error).
    """
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        if not connection:
            print("Database connection error in execute_query.")
            return None
        cursor = connection.cursor(dictionary=True) # dictionary=True returns rows as dictionaries
        cursor.execute(query, params)
        # Since this function is for read-only context, we only expect SELECT queries.
        if fetch_one:
            return cursor.fetchone()
        return cursor.fetchall()
    except Error as e:
        print(f"Error executing query: {e}")
        return None
    finally:
        if cursor:
            cursor.close()
        close_db_connection(connection)

def get_entity_list(
    data: dict,
    table_name: str,
    search_fields_mapping: dict,
    select_columns: List[str]
):
    """
    Generic function to fetch a paginated and filterable list of entities from a database table.

    Args:
        data (dict): The request JSON data containing pagination and search parameters.
        table_name (str): The name of the database table to query.
        search_fields_mapping (dict): A dictionary mapping request parameter names
                                      to database column names and their expected types.
                                      Example: {'id_search': {'db_column': 'id', 'type': 'int'},
                                                'username_search': {'db_column': 'username', 'type': 'string', 'comparison': 'like'}}
        select_columns (List[str]): A list of column names to select from the table.

    Returns:
        tuple: (response, status_code)
               - response (flask.Response): JSON response object with data and pagination.
               - status_code (int): HTTP status code (200 for success, 400 for bad request, 500 for internal error).
    """
    page = int(data.get('page', 1))
    limit = int(data.get('limit', DEFAULT_ITEMS_PER_PAGE))
    offset = (page - 1) * limit

    # Build the base query and parameters
    select_cols_str = ", ".join(select_columns)
    base_select_query = f"SELECT {select_cols_str} FROM {table_name}"
    base_count_query = f"SELECT COUNT(*) AS total FROM {table_name}"
    where_clauses = []
    query_params = []
    count_params = []

    # Dynamically add search conditions
    for param_name, field_info in search_fields_mapping.items():
        search_value = data.get(param_name)
        if search_value is not None and str(search_value).strip() != '':
            db_column = field_info['db_column']
            param_type = field_info.get('type', 'string')
            comparison = field_info.get('comparison', '=') # Default to exact match

            try:
                if param_type == 'int':
                    # Convert to int for exact match comparison
                    int_value = int(search_value)
                    where_clauses.append(f"{db_column} = %s")
                    query_params.append(int_value)
                    count_params.append(int_value)
                elif param_type == 'datetime':
                    # For datetime, use LIKE comparison on text representation
                    # Adjust for specific DB if not PostgreSQL (e.g., CAST for MySQL)
                    where_clauses.append(f"{db_column}::text LIKE %s")
                    query_params.append(f"%{search_value}%")
                    count_params.append(f"%{search_value}%")
                else: # Default to string type, use LIKE for partial match unless comparison is '='
                    if comparison == 'like':
                        where_clauses.append(f"{db_column} LIKE %s")
                        query_params.append(f"%{search_value}%")
                        count_params.append(f"%{search_value}%")
                    else: # Exact string match
                        where_clauses.append(f"{db_column} = %s")
                        query_params.append(search_value)
                        count_params.append(search_value)
            except ValueError:
                return jsonify({"error": f"Invalid '{param_name}' parameter. Must be an integer."}), 400
            except Exception as e:
                return jsonify({"error": f"Error processing search parameter '{param_name}': {e}"}), 400

    # Combine where clauses
    if where_clauses:
        where_string = " WHERE " + " AND ".join(where_clauses)
        base_select_query += where_string
        base_count_query += where_string

    # Add LIMIT and OFFSET for pagination to the select query
    select_query = f"{base_select_query} LIMIT %s OFFSET %s"
    query_params.extend([limit, offset])

    # Execute queries
    entity_data = execute_query(select_query, query_params)
    total_count_result = execute_query(base_count_query, count_params, fetch_one=True)

    if entity_data is None or total_count_result is None:
        return jsonify({"error": "Failed to retrieve data from database. Check database connection and queries."}), 500

    total_items = total_count_result['total']
    total_pages = (total_items + limit - 1) // limit # Ceiling division

    # Ensure DateTime objects are converted to strings for JSON serialization
    for item in entity_data:
        for col in ['createdAt', 'updatedAt', 'created_at', 'updated_at']: # Check both naming conventions
            if col in item and item[col] is not None:
                try:
                    item[col] = item[col].isoformat()
                except AttributeError:
                    # If it's not a datetime object, leave as is or handle appropriately
                    pass

    return send_response(
        data=entity_data,
        page=page,
        limit=limit,
        total_items=total_items,
        total_pages=total_pages
    )

# --- Specific List Service Functions ---

def get_users_list_service(data: dict):
    """Service function to get a list of users with pagination and search."""
    search_fields = {
        'id_search': {'db_column': 'id', 'type': 'int'},
        'username_search': {'db_column': 'username', 'type': 'string', 'comparison': 'like'},
        'first_name_search': {'db_column': 'first_name', 'type': 'string', 'comparison': 'like'},
        'last_name_search': {'db_column': 'last_name', 'type': 'string', 'comparison': 'like'},
        'email_search': {'db_column': 'email', 'type': 'string', 'comparison': 'like'},
        'mobile_search': {'db_column': 'mobile', 'type': 'string', 'comparison': 'like'},
        'status_search': {'db_column': 'status', 'type': 'string', 'comparison': '='}
    }
    select_cols = ['id', 'username', 'first_name', 'last_name', 'email', 'mobile', 'status']
    return get_entity_list(data, 'ds_user', search_fields, select_cols)

def get_documents_list_service(data: dict):
    """Service function to get a list of uploaded documents with pagination and search."""
    search_fields = {
        'id': {'db_column': 'id', 'type': 'int'},
        'env_id': {'db_column': 'env_id', 'type': 'int'},
        'type': {'db_column': 'type', 'type': 'string', 'comparison': 'like'},
        'parent_id': {'db_column': 'parent_id', 'type': 'string', 'comparison': 'like'},
        'ref_id': {'db_column': 'ref_id', 'type': 'string', 'comparison': 'like'},
        'module_id': {'db_column': 'module_id', 'type': 'int'},
        'status': {'db_column': 'status', 'type': 'string', 'comparison': '='},
        'created_at': {'db_column': 'createdAt', 'type': 'datetime'}, # Note: using 'createdAt' for DB column
        'updated_at': {'db_column': 'updatedAt', 'type': 'datetime'}  # Note: using 'updatedAt' for DB column
    }
    select_cols = ['id', 'env_id', 'type', 'parent_id', 'ref_id', 'module_id', 'status', 'createdAt', 'updatedAt']
    return get_entity_list(data, 'ds_document', search_fields, select_cols)

def get_access_logs_list_service(data: dict):
    """Service function to get a list of access logs with pagination and search."""
    search_fields = {
        'id': {'db_column': 'id', 'type': 'int'},
        'env_id': {'db_column': 'env_id', 'type': 'int'},
        'url': {'db_column': 'url', 'type': 'string', 'comparison': 'like'},
        'method': {'db_column': 'method', 'type': 'string', 'comparison': 'like'},
        'status': {'db_column': 'status', 'type': 'string', 'comparison': '='},
        'created_at': {'db_column': 'createdAt', 'type': 'datetime'},
        'updated_at': {'db_column': 'updatedAt', 'type': 'datetime'}
    }
    select_cols = ['id', 'env_id', 'url', 'method', 'status', 'createdAt', 'updatedAt']
    return get_entity_list(data, 'ds_access_log', search_fields, select_cols)

def get_document_master_list_service(data: dict):
    """Service function to get a list of document master entries with pagination and search."""
    search_fields = {
        'id': {'db_column': 'id', 'type': 'int'},
        'env_id': {'db_column': 'env_id', 'type': 'int'},
        'module_id': {'db_column': 'module_id', 'type': 'int'},
        'type': {'db_column': 'type', 'type': 'string', 'comparison': 'like'},
        'status': {'db_column': 'status', 'type': 'string', 'comparison': '='},
        'created_at': {'db_column': 'createdAt', 'type': 'datetime'},
        'updated_at': {'db_column': 'updatedAt', 'type': 'datetime'}
    }
    select_cols = ['id', 'env_id', 'module_id', 'type', 'status', 'createdAt', 'updatedAt']
    return get_entity_list(data, 'ds_document_master', search_fields, select_cols)

def get_app_configs_list_service(data: dict):
    """Service function to get a list of application configurations with pagination and search."""
    search_fields = {
        'id': {'db_column': 'id', 'type': 'int'},
        'env': {'db_column': 'env', 'type': 'string', 'comparison': 'like'},
        'code': {'db_column': 'code', 'type': 'string', 'comparison': 'like'},
        'app_api_config': {'db_column': 'app_api_config', 'type': 'string', 'comparison': 'like'},
        'created_at': {'db_column': 'createdAt', 'type': 'datetime'}, # Assuming 'createdAt' in DB
        'updated_at': {'db_column': 'updatedAt', 'type': 'datetime'}  # Assuming 'updatedAt' in DB
    }
    select_cols = ['id', 'env', 'code', 'app_api_config', 'createdAt', 'updatedAt']
    return get_entity_list(data, 'ds_application_config', search_fields, select_cols)


