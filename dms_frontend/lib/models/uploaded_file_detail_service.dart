// lib/services/app_config_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ui_for_user_list/models/uploaded_file_detail.dart';


class UploadedFileService {
  // Use 127.0.0.1 for web (Edge) on the same machine as Flask
  static const String _baseUrl = 'http://127.0.0.1:5000/admin';

  // Removed: static const String _tempAuthToken = '...';

  // token parameter is now required
  Future<Uploadedfile?> fetchUploadedFileDetails(int upload, String token) async { // Added 'token' parameter
    if (token.isEmpty) {
      throw Exception('Authentication token is missing. Please provide a valid token.');
    }

    final url = Uri.parse('$_baseUrl/documents/details');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Use the passed token
        },
        body: json.encode({'upload_id': upload}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return Uploadedfile.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token. Please log in again.');
      } else if (response.statusCode == 404) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Uploaded File not found. Check the ID or API path: $url');
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Bad Request: Missing expected ID in body.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load uploaded file details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching uploaded file details from URL: $url - $e');
    }
  }
}
