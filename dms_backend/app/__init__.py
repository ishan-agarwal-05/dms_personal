from flask import Flask, request, jsonify
from flask_jwt_extended import JWTManager
from database import init_db_pool
from flask_cors import CORS

from routes.document_routes import document_api_bp
from routes.auth_routes import auth_bp
from routes.admin_routes import admin_bp

app = Flask(__name__)

CORS(app)

app.config["JWT_SECRET_KEY"] = "your-secret-key"
jwt = JWTManager(app)
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # Max file size = 16MB

with app.app_context():
    init_db_pool(pool_size=10)

# Register the blueprints
app.register_blueprint(document_api_bp, url_prefix='/api')
app.register_blueprint(auth_bp, url_prefix='/auth')
app.register_blueprint(admin_bp, url_prefix='/admin')

if __name__ == "__main__":
    app.run(debug=True)