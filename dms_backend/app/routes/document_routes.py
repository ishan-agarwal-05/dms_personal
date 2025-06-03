from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required
from app.services.document_services import delete_document_service, list_documents_service, handle_file_upload, log_api_operation
from app.utils.request_utils import get_request_context, parse_request_data

document_api_bp = Blueprint('document_routes', __name__) # Updated Blueprint name for consistency

def handle_request_with_logging(service_function, is_file_upload=False):
    """
    A helper function to orchestrate common request parsing,
    service function calling, and access logging for API endpoints.
    """
    # Get common request context
    req_context = get_request_context()
    user_id = req_context["user_id"]
    claims = req_context["claims"]

    # Parse request data based on type
    request_data_for_service, request_body_for_logging, log_env_id = parse_request_data(is_file_upload)

    # Call the appropriate service function
    response_data = None
    if is_file_upload:
        file_obj, metadata_str = request_data_for_service
        response_data = service_function(file_obj, metadata_str, user_id=user_id)
    else:
        # All non-file-upload services now consistently expect 'user_id' as the second argument
        response_data = service_function(request_data_for_service, user_id=user_id)

    # Log the API operation
    log_api_operation(claims, req_context, response_data, request_body_for_logging, log_env_id)

    return jsonify(response_data), response_data.get("responseCode", 500)


@document_api_bp.route('/document/delete', methods=['DELETE'])
@jwt_required()
def delete_document_route():
    """Handles the DELETE /api/document/delete endpoint."""
    return handle_request_with_logging(delete_document_service)

@document_api_bp.route("/document/list", methods=["POST"]) # Changed from /get-documents to /document/list
@jwt_required()
def list_documents_route(): # Renamed function for clarity
    """Handles the POST /api/document/list endpoint."""
    return handle_request_with_logging(list_documents_service) # Still calls list_documents_service

@document_api_bp.route("/document/upload", methods=["POST"]) # Changed from /upload to /document/upload
@jwt_required()
def upload_file_route():
    """Handles the POST /api/document/upload endpoint."""
    return handle_request_with_logging(handle_file_upload, is_file_upload=True)