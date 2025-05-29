// lib/services/app_config_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ui_for_user_list/models/app_config_details.dart';

class AppConfigService {
  // Use 127.0.0.1 for web (Edge) on the same machine as Flask
  static const String _baseUrl = 'http://127.0.0.1:5000/admin';

  // Removed: static const String _tempAuthToken = '...';

  // token parameter is now required
  Future<Appconfig?> fetchAppConfigDetails(int configId, String token) async {
    if (token.isEmpty) {
      throw Exception('Authentication token is missing. Please provide a valid token.');
    }

    final url = Uri.parse('$_baseUrl/application_config/details'); 

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Use the passed token
        },
        body: json.encode({'app_config_id': configId}), // Send config ID in the request body
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return Appconfig.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token. Please log in again.');
      } else if (response.statusCode == 404) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'App configuration not found. Check the ID or API path: $url');
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Bad Request: Missing expected ID in body.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load app config details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching app config details from URL: $url - $e');
    }
  }
}
