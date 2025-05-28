from flask import request
from flask_jwt_extended import get_jwt
import json

def get_request_context():
    claims = get_jwt()
    user_id = claims.get("user_id")

    return {
        "user_id": user_id,
        "url": request.url,
        "method": request.method,
        "ip": request.remote_addr,
        "claims": claims
    }

def parse_request_data(is_file_upload=False):
    """
    Parses request data based on whether it's a file upload or a JSON request.
    Returns:
        tuple: (request_data_for_service, request_body_for_logging, log_env_id)
    """
    log_env_id = None
    request_data_for_service = None
    request_body_for_logging = {}

    if is_file_upload:
        file_obj = request.files.get('other_documents')
        request_data_form = request.form.get('data')

        parsed_metadata = {}
        if request_data_form:
            try:
                parsed_metadata = json.loads(request_data_form)
                log_env_id = parsed_metadata.get("application_id")
            except json.JSONDecodeError:
                pass

        request_data_for_service = (file_obj, request_data_form)
        request_body_for_logging = {
            "file_name": file_obj.filename if file_obj else None,
            "data": request_data_form
        }
    else:
        request_body_json = request.get_json()
        if request_body_json:
            log_env_id = request_body_json.get("application_id")
        request_data_for_service = request_body_json
        request_body_for_logging = request_body_json

    return request_data_for_service, request_body_for_logging, log_env_id