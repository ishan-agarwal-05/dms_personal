from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required

admin_bp = Blueprint('admin_routes', __name__)

# --- Users Endpoints ---
@admin_bp.route('/users/list', methods=['POST'])
@jwt_required()
def admin_users_list():
    return jsonify({"message": "Admin - List Users endpoint reached."}), 200

@admin_bp.route('/users/details', methods=['POST'])
@jwt_required()
def admin_users_details():
    data = request.get_json()
    record_id = data.get('id')
    return jsonify({"message": f"Admin - Details for User ID: {record_id} endpoint reached."}), 200

# --- Documents Endpoints ---
@admin_bp.route('/documents/list', methods=['POST'])
@jwt_required()
def admin_documents_list():
    return jsonify({"message": "Admin - List Documents endpoint reached."}), 200

@admin_bp.route('/documents/details', methods=['POST'])
@jwt_required()
def admin_documents_details():
    data = request.get_json()
    record_id = data.get('id')
    return jsonify({"message": f"Admin - Details for Document ID: {record_id} endpoint reached."}), 200

# --- Access Logs Endpoints ---
@admin_bp.route('/access_logs/list', methods=['POST'])
@jwt_required()
def admin_access_logs_list():
    return jsonify({"message": "Admin - List Access Logs endpoint reached."}), 200

@admin_bp.route('/access_logs/details', methods=['POST'])
@jwt_required()
def admin_access_logs_details():
    data = request.get_json()
    record_id = data.get('id')
    return jsonify({"message": f"Admin - Details for Access Log ID: {record_id} endpoint reached."}), 200

# --- Document Master Endpoints ---
@admin_bp.route('/document_master/list', methods=['POST'])
@jwt_required()
def admin_document_master_list():
    return jsonify({"message": "Admin - List Document Master endpoint reached."}), 200

@admin_bp.route('/document_master/details', methods=['POST'])
@jwt_required()
def admin_document_master_details():
    data = request.get_json()
    record_id = data.get('id')
    return jsonify({"message": f"Admin - Details for Document Master ID: {record_id} endpoint reached."}), 200

# --- Application Config Endpoints ---
@admin_bp.route('/application_config/list', methods=['POST'])
@jwt_required()
def admin_application_config_list():
    return jsonify({"message": "Admin - List Application Config endpoint reached."}), 200

@admin_bp.route('/application_config/details', methods=['POST'])
@jwt_required()
def admin_application_config_details():
    data = request.get_json()
    record_id = data.get('id')
    return jsonify({"message": f"Admin - Details for Application Config ID: {record_id} endpoint reached."}), 200