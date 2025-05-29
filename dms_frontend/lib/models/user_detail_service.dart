import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ui_for_user_list/models/user_details.dart';


class UserService {
  static const String _baseUrl = 'http://127.0.0.1:5000/admin';

  // CORRECTED: Re-added the 'token' parameter
  Future<UserD?> fetchUserDetails(int userId, String token) async {
    if (token.isEmpty) {
      throw Exception('Authentication token is missing. Please log in.');
    }

    final url = Uri.parse('$_baseUrl/users/details'); // Assumed backend path

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // Backend expects 'user_id' in the request body
        body: json.encode({'user_id': userId}), // Dynamically pass userId
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return UserD.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token. Please log in again.');
      } else if (response.statusCode == 404) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'User not found. Check the ID or API path: $url');
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Bad Request: Missing expected ID in body.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load user details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user details from URL: $url - $e');
    }
  }
}
