import os
from dotenv import load_dotenv

# Load environment variables from .env file at the start
# This ensures variables are available to all modules during import
load_dotenv()

# Now import the app (which may use env variables during initialization)
from app import app

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    host = os.getenv("HOST", "0.0.0.0")
    debug = os.getenv("DEBUG", "False").lower() == "true"
    print(f"Starting server on {host}:{port} (debug={debug})")
    
    # Run the app
    app.run(host=host, port=port, debug=debug)