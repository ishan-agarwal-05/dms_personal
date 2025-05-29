// ui_for_login/lib/main.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Required for jsonEncode and jsonDecode
import 'package:ui_for_user_list/user_list_main.dart'; // Import UserManagementScreen from the other project/package
import 'package:shared_preferences/shared_preferences.dart'; // For storing user session

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login and Dashboard', // Main app title
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(), // Starting with the Login Screen
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Global state variables for error messages
  String? _backendErrorMessage;

  // error message state variables
  String? _usernameError;
  String? _passwordError;

  // Figma design dimensions for scaling
  static const double figmaWidth = 1440.0;
  static const double figmaHeight = 1024.0;

  // Define colors from Figma variables
  static const Color b1Color = Color(0xFF252C70); // Dark Blue
  static const Color b2Color = Color(0xFFDB7413); // Orange

  @override
  void dispose() {
    _usernameController.dispose(); // Dispose username controller
    _passwordController.dispose();
    super.dispose();
  }

  // This function will handle the login attempt by calling your backend API
  void _handleLogin() async {
    final String username = _usernameController.text.trim(); // Trim whitespace
    final String password = _passwordController.text;

    // Reset previous error messages
    setState(() {
      _usernameError = null;
      _passwordError = null;
      _backendErrorMessage = null;
    });

    // Client-side validation - show errors below the fields
    bool isValid = true;

    if (username.isEmpty) {
      setState(() {
        _usernameError = 'Username is required';
      });
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password is required';
      });
      isValid = false;
    }

    if (!isValid) {
      return; // Stop if validation fails
    }
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    // Your actual backend login API endpoint
    const String apiUrl =
        'http://127.0.0.1:5000/auth/login'; // Ensure this is correct for your Flask login API

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Login successful
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print('Login successful: $responseData');

        final String? authToken = responseData['access_token'];

        if (authToken != null) {
          print('Authorization Token: $authToken');
          // Save the token for future authenticated requests
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', authToken);

          // Navigate to the UserManagementScreen on successful login
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) =>
                    const UserManagementScreen(), // Navigate to UserManagementScreen
              ),
            );
          }
        } else {
          setState(() {
            _backendErrorMessage = 'Login successful, but no token received.';
          });
        }
      } else {
        // Login failed (e.g., 401 Unauthorized, 400 Bad Request)
        String errorMessage =
            'Login failed. Your username or password may be incorrect. Please try again.';
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          errorMessage = errorData['msg'] ?? errorMessage;
        } catch (e) {
          print('Failed to parse error response: $e');
        }

        setState(() {
          _backendErrorMessage = errorMessage; // Set the backend error message
        });

        print(
            'Login failed: Status ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      // Network/connection errors
      setState(() {
        _backendErrorMessage =
            'Network error: Could not connect to the server.';
      });
      print('Error during login: $e');
    } finally {
      setState(() {
        _isLoading =
            false; // Hide loading indicator regardless of success or failure
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    // Login card dimensions (assuming a fixed width for responsiveness)
    final double cardWidth =
        screenSize.width > 600 ? 400.0 : screenSize.width * 0.85;

    return Scaffold(
      backgroundColor: Colors.white, // Light grey background
      body: Stack(
        children: [
          // Top-right Orange Ellipse (B2)
          _buildScaledCircle(
            figmaTop:
                -232.673, // Derived from center Y - radius (-71 - 161.673)
            figmaLeft:
                1046.327, // Derived from center X - radius (1208 - 161.673)
            figmaWidthOfElement: 323.346,
            color: b2Color,
            screenSize: screenSize,
            figmaWidth: figmaWidth,
            figmaHeight: figmaHeight,
            alignment: Alignment.topRight, // Position from top-right
          ),

          // Top-right Blue Ellipse (B1)
          _buildScaledCircle(
            figmaTop: -214.46, // Derived from center Y - radius (-4.6 - 209.86)
            figmaLeft:
                1299.59, // Derived from center X - radius (1509.45 - 209.86)
            figmaWidthOfElement: 419.72,
            color: b1Color,
            screenSize: screenSize,
            figmaWidth: figmaWidth,
            figmaHeight: figmaHeight,
            alignment: Alignment.topRight, // Position from top-right
          ),

          // Bottom-left Blue Ellipse (B1)
          _buildScaledCircle(
            figmaTop: 879.14, // UPDATED based on new center coordinates
            figmaLeft: -207.61, // UPDATED based on new center coordinates
            figmaWidthOfElement: 419.72,
            color: b1Color,
            screenSize: screenSize,
            figmaWidth: figmaWidth,
            figmaHeight: figmaHeight,
            alignment: Alignment.bottomLeft, // This remains correct
          ),

          // Bottom-left Orange Ellipse (B2)
          _buildScaledCircle(
            figmaTop: 975.325, // UPDATED based on new center coordinates
            figmaLeft: 73.325, // UPDATED based on new center coordinates
            figmaWidthOfElement: 323.35, // Using 323.35 as given diameter
            color: b2Color,
            screenSize: screenSize,
            figmaWidth: figmaWidth,
            figmaHeight: figmaHeight,
            alignment: Alignment.bottomLeft, // This remains correct
          ),

          // Login Card - Centered vertically with conditional scrolling and error above username field
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate if content would overflow and need scrolling
                final bool needsScrolling = constraints.maxHeight <
                    650; // Adjust this threshold based on your form height

                return needsScrolling
                    ? SingleChildScrollView(
                        child: _buildLoginCard(cardWidth, screenSize),
                      )
                    : _buildLoginCard(cardWidth, screenSize);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build and position the scaled circles
  Widget _buildScaledCircle({
    required double figmaTop,
    required double figmaLeft,
    required double
        figmaWidthOfElement, // Assuming height is same as width for circles
    required Color color,
    required Size screenSize,
    required double figmaWidth,
    required double figmaHeight,
    required Alignment
        alignment, // To determine if it's top-right, bottom-left etc.
  }) {
    double scaledWidth = figmaWidthOfElement / figmaWidth * screenSize.width;
    double scaledHeight = scaledWidth; // Keep aspect ratio for circles

    double? top;
    double? bottom;
    double? left;
    double? right;

    // Calculate top/bottom based on alignment
    if (alignment == Alignment.topLeft || alignment == Alignment.topRight) {
      top = figmaTop / figmaHeight * screenSize.height;
    } else {
      // Bottom-left or Bottom-right
      bottom = (figmaHeight - (figmaTop + figmaWidthOfElement)) /
          figmaHeight *
          screenSize.height;
    }

    // Calculate left/right based on alignment
    if (alignment == Alignment.topLeft || alignment == Alignment.bottomLeft) {
      left = figmaLeft / figmaWidth * screenSize.width;
    } else {
      // Top-right or Bottom-right
      right = (figmaWidth - (figmaLeft + figmaWidthOfElement)) /
          figmaWidth *
          screenSize.width;
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: scaledWidth,
        height: scaledHeight,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // Extracted login card to a separate method for reuse
  Widget _buildLoginCard(double cardWidth, Size screenSize) {
    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 8.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/techfour.png',
                height: 80,
              ),
              const SizedBox(height: 24.0),
              const Text(
                'Sign in',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Welcome back, please login to your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16.0),

              // Backend error message box - displayed when _backendErrorMessage is not null
              if (_backendErrorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 16.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _backendErrorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14.0,
                    ),
                  ),
                ),

              const SizedBox(height: 16.0),

              // Username field with error message
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Username*',
                      hintText: 'Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      labelStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                      ),
                      hintStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                      ),
                      // Add error border when error exists
                      errorBorder: _usernameError != null
                          ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(color: Colors.red),
                            )
                          : null,
                    ),
                  ),
                  if (_usernameError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 6.0),
                      child: Text(
                        _usernameError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12.0,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16.0),

              // Password field with error message
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password*',
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      labelStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                      ),
                      hintStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                      ),
                      // Add error border when error exists
                      errorBorder: _passwordError != null
                          ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(color: Colors.red),
                            )
                          : null,
                    ),
                  ),
                  if (_passwordError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 6.0),
                      child: Text(
                        _passwordError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12.0,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16.0),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    print('Forgot Password clicked');
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: b1Color,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
