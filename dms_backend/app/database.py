import mysql.connector
from mysql.connector import Error
from mysql.connector import pooling
import os # Import the os module to access environment variables
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from .env file

# Database connection details are now read from environment variables
DB_CONFIG = {
    'host': os.getenv('DB_HOST'),
    'database': os.getenv('DB_NAME'), 
    'user': os.getenv('DB_USER'), 
    'password': os.getenv('DB_PASSWORD')
}

# You can also add a check to ensure critical variables are set
if not all([DB_CONFIG['host'], DB_CONFIG['database'], DB_CONFIG['user']]):
    raise ValueError("Missing one or more critical database environment variables (DB_HOST, DB_NAME, DB_USER)")

# Global variable for the connection pool
db_connection_pool = None

def init_db_pool(pool_name='my_app_pool', pool_size=5):
    """
    Initializes the database connection pool.
    This should be called once when the application starts.
    """
    global db_connection_pool
    if db_connection_pool is None:
        try:
            db_connection_pool = pooling.MySQLConnectionPool(
                pool_name=pool_name,
                pool_size=pool_size, # Number of connections in the pool
                **DB_CONFIG
            )
            print(f"Database connection pool '{pool_name}' initialized with size {pool_size}.")
        except Error as e:
            print(f"Error initializing database connection pool: {e}")
            db_connection_pool = None # Ensure pool is None if initialization fails
            raise # Re-raise the exception to indicate a critical startup failure


def get_db_connection():
    """
    Gets a connection from the pool.
    """
    if db_connection_pool is None:
        print("CRITICAL: Database connection pool not initialized.")
        return None
    try:
        conn = db_connection_pool.get_connection()
        if conn.is_connected():
            return conn
    except Error as e:
        print(f"Error getting connection from pool: {e}")
        return None

def get_db_cursor(conn):
    """
    Returns a cursor object for the given connection.
    """
    if conn:
        return conn.cursor(dictionary=True) # Use dictionary=True to fetch rows as dictionaries
    return None

def close_db_connection(conn, cursor=None):
    """
    Closes the database cursor and connection.
    """
    if cursor:
        cursor.close()
    if conn and conn.is_connected():
        conn.close()  # This line returns the connection to the pool

