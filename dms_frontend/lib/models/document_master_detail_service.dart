// lib/services/app_config_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ui_for_user_list/models/document_master_detail.dart';

class DocumentMasterService {
  static const String _baseUrl = 'http://127.0.0.1:5000/admin';

  // Removed: static const String _tempAuthToken = '...';

  // token parameter is now required
  Future<DM?> fetchDocumentMasterDetails(int documentMasterId, String token) async { // Added 'token' parameter
    if (token.isEmpty) {
      throw Exception('Authentication token is missing. Please provide a valid token.');
    }

    // Assuming backend endpoint is /admin/document_master/details and expects 'master_id'
    final url = Uri.parse('$_baseUrl/document_master/details'); // Corrected API path

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Use the passed token
        },
        // Backend expects 'master_id' in the request body
        body: json.encode({'ds_master_id': documentMasterId}), // Corrected parameter name
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return DM.fromJson(responseData); // Corrected model type
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token. Please log in again.');
      } else if (response.statusCode == 404) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Document Master not found. Check the ID or API path: $url');
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Bad Request: Missing expected ID in body.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load document master details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching document master details from URL: $url - $e');
    }
  }
}
