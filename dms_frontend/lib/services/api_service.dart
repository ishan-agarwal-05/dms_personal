import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();
  
  ApiService._();

  // Environment configuration
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
  int get timeout => int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;
  bool get debugMode => dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  // API Endpoints
  String get authLoginEndpoint => '$baseUrl/auth/login';
  String get usersListEndpoint => '$baseUrl/admin/users/list';
  String get userDetailsEndpoint => '$baseUrl/admin/users/details';
  String get documentMasterListEndpoint => '$baseUrl/admin/document_master/list';
  String get documentMasterDetailsEndpoint => '$baseUrl/admin/document_master/details';
  String get appConfigListEndpoint => '$baseUrl/admin/application_config/list';
  String get appConfigDetailsEndpoint => '$baseUrl/admin/application_config/details';
  String get uploadedFilesListEndpoint => '$baseUrl/admin/documents/list';
  String get uploadedFilesDetailsEndpoint => '$baseUrl/admin/documents/details';
  String get accessLogsListEndpoint => '$baseUrl/admin/access_logs/list';
  String get accessLogsDetailsEndpoint => '$baseUrl/admin/access_logs/details';

  // Helper method to get auth token
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Helper method to decode JWT token and get user info
  Future<Map<String, dynamic>?> getUserInfoFromToken() async {
    final token = await getAuthToken();
    if (token == null) return null;
    
    try {
      // Split JWT token (header.payload.signature)
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      // Decode the payload (second part)
      String payload = parts[1];
      
      // Add padding if needed for base64 decoding
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      
      // Decode base64
      final decoded = utf8.decode(base64Decode(payload));
      final Map<String, dynamic> claims = jsonDecode(decoded);
      
      return claims;
    } catch (e) {
      if (debugMode) {
        print('Error decoding JWT token: $e');
      }
      return null;
    }
  }

  // Helper method to get user first name from token
  Future<String> getUserFirstName() async {
    final userInfo = await getUserInfoFromToken();
    return userInfo?['first_name'] ?? 'User';
  }

  // Helper method to get common headers
  Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };

    if (includeAuth) {
      final token = await getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Generic GET request
  Future<http.Response> get(String endpoint, {bool includeAuth = true}) async {
    final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
    final headers = await getHeaders(includeAuth: includeAuth);
    
    if (debugMode) {
      print('GET Request to: $url');
      print('Headers: $headers');
    }

    return await http.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(Duration(milliseconds: timeout));
  }

  // Generic POST request
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
    final headers = await getHeaders(includeAuth: includeAuth);
    
    if (debugMode) {
      print('POST Request to: $url');
      print('Headers: $headers');
      print('Body: ${jsonEncode(body)}');
    }

    return await http.post(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(Duration(milliseconds: timeout));
  }

  // Generic PUT request
  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
    final headers = await getHeaders(includeAuth: includeAuth);
    
    if (debugMode) {
      print('PUT Request to: $url');
      print('Headers: $headers');
      print('Body: ${jsonEncode(body)}');
    }

    return await http.put(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(Duration(milliseconds: timeout));
  }

  // Generic DELETE request
  Future<http.Response> delete(String endpoint, {bool includeAuth = true}) async {
    final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
    final headers = await getHeaders(includeAuth: includeAuth);
    
    if (debugMode) {
      print('DELETE Request to: $url');
      print('Headers: $headers');
    }

    return await http.delete(
      Uri.parse(url),
      headers: headers,
    ).timeout(Duration(milliseconds: timeout));
  }

  // Specific API methods for common operations
  
  // Authentication
  Future<http.Response> login(String username, String password) async {
    return await post(
      '/auth/login',
      body: {
        'username': username,
        'password': password,
      },
      includeAuth: false,
    );
  }

  // Users API
  Future<http.Response> getUsersList({
    int page = 1,
    int limit = 5,
    String? id,
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    String? status,
  }) async {
    return await post('/admin/users/list', body: {
      'page': page,
      'limit': limit,
      if (id != null && id.isNotEmpty) 'id': id,
      if (username != null && username.isNotEmpty) 'username': username,
      if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
      if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
      if (status != null) 'status': status,
    });
  }

  Future<http.Response> getUserDetails(int userId) async {
    return await post('/admin/users/details', body: {'user_id': userId});
  }

  // Document Master API
  Future<http.Response> getDocumentMasterList({
    int page = 1,
    int limit = 5,
    String? id,
    String? envId,
    String? type,
    String? moduleId,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) async {
    return await post('/admin/document_master/list', body: {
      'page': page,
      'limit': limit,
      if (id != null && id.isNotEmpty) 'id': id,
      if (envId != null && envId.isNotEmpty) 'env_id': envId,
      if (type != null && type.isNotEmpty) 'type': type,
      if (moduleId != null && moduleId.isNotEmpty) 'module_id': moduleId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (createdAt != null && createdAt.isNotEmpty) 'created_at': createdAt,
      if (updatedAt != null && updatedAt.isNotEmpty) 'updated_at': updatedAt,
    });
  }

  Future<http.Response> getDocumentMasterDetails(int documentMasterId) async {
    return await post('/admin/document_master/details', body: {'ds_master_id': documentMasterId});
  }

  // App Config API
  Future<http.Response> getAppConfigList({
    int page = 1,
    int limit = 5,
    Map<String, dynamic>? filters,
  }) async {
    final Map<String, dynamic> body = {
      'page': page,
      'limit': limit,
    };
    if (filters != null) {
      body.addAll(filters);
    }
    return await post('/admin/application_config/list', body: body);
  }

  Future<http.Response> getAppConfigDetails(int appConfigId) async {
    return await post('/admin/application_config/details', body: {'app_config_id': appConfigId});
  }

  // Uploaded Files API
  Future<http.Response> getUploadedFilesList({
    int page = 1,
    int limit = 5,
    Map<String, dynamic>? filters,
  }) async {
    final Map<String, dynamic> body = {
      'page': page,
      'limit': limit,
    };
    if (filters != null) {
      body.addAll(filters);
    }
    return await post('/admin/documents/list', body: body);
  }

  Future<http.Response> getUploadedFilesDetails(int uploadedFileId) async {
    return await post('/admin/documents/details', body: {'upload_id': uploadedFileId});
  }

  // Access Logs API
  Future<http.Response> getAccessLogsList({
    int page = 1,
    int limit = 5,
    Map<String, dynamic>? filters,
  }) async {
    final Map<String, dynamic> body = {
      'page': page,
      'limit': limit,
    };
    if (filters != null) {
      body.addAll(filters);
    }
    return await post('/admin/access_logs/list', body: body);
  }

  Future<http.Response> getAccessLogsDetails(int accessLogId) async {
    return await post('/admin/access_logs/details', body: {'access_log_id': accessLogId});
  }

  // Environment info for debugging
  void printEnvironmentInfo() {
    if (debugMode) {
      print('=== API Service Configuration ===');
      print('Environment: $environment');
      print('Base URL: $baseUrl');
      print('Timeout: ${timeout}ms');
      print('Debug Mode: $debugMode');
      print('================================');
    }
  }
}