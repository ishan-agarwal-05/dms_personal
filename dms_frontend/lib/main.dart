import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dms_frontend/screens/auth/main_login.dart' as login;
import 'package:dms_frontend/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('Could not load .env file: $e');
    // Continue with default values
  }
  
  // Print environment info in debug mode
  ApiService.instance.printEnvironmentInfo();
  
  login.main();
}