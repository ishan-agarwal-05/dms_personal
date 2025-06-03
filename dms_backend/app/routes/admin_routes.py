from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required
from app.services.admin_services import (
    get_user_details,
    get_app_config_details,
    get_upload_detail_services,
    get_access_log_details,
    get_ds_master_details
)
from app.services.admin_services import ( # Import the new list service functions
    get_request_data, # Import get_request_data to use it consistently
    get_users_list_service,
    get_documents_list_service,
    get_access_logs_list_service,
    get_document_master_list_service,
    get_app_configs_list_service
)

admin_bp = Blueprint('admin_routes', __name__)

def list_route_wrapper(service_function):
    request_data, error_response, status_code = get_request_data()
    if error_response:
        return jsonify(error_response), status_code
    return service_function(request_data)

def details_route_wrapper(service_function):
    data = request.get_json()
    response, status_code = service_function(data)
    return response, status_code

# --- Users Endpoints ---
@admin_bp.route('/users/list', methods=['POST'])
@jwt_required()
def admin_users_list():
    return list_route_wrapper(get_users_list_service)

@admin_bp.route('/users/details', methods=['POST'])
@jwt_required()
def admin_users_details():
    return details_route_wrapper(get_user_details)

# --- Documents Endpoints ---
@admin_bp.route('/documents/list', methods=['POST'])
@jwt_required()
def admin_documents_list():
    return list_route_wrapper(get_documents_list_service)

@admin_bp.route('/documents/details', methods=['POST'])
@jwt_required()
def admin_documents_details():
    return details_route_wrapper(get_upload_detail_services)

# --- Access Logs Endpoints ---
@admin_bp.route('/access_logs/list', methods=['POST'])
@jwt_required()
def admin_access_logs_list():
    return list_route_wrapper(get_access_logs_list_service)

@admin_bp.route('/access_logs/details', methods=['POST'])
@jwt_required()
def admin_access_logs_details():
    return details_route_wrapper(get_access_log_details)

# --- Document Master Endpoints ---
@admin_bp.route('/document_master/list', methods=['POST'])
@jwt_required()
def admin_document_master_list():
    return list_route_wrapper(get_document_master_list_service)

@admin_bp.route('/document_master/details', methods=['POST'])
@jwt_required()
def admin_document_master_details():
    return details_route_wrapper(get_ds_master_details)

# --- Application Config Endpoints ---
@admin_bp.route('/application_config/list', methods=['POST'])
@jwt_required()
def admin_application_config_list():
    return list_route_wrapper(get_app_configs_list_service)

@admin_bp.route('/application_config/details', methods=['POST'])
@jwt_required()
def admin_application_config_details():
    return details_route_wrapper(get_app_config_details)
