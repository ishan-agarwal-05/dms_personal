import 'package:flutter/material.dart';
import 'package:techfour_dms_flutter_frontend/screens/auth/login_screen.dart'; // Import your LoginScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disable the debug banner
      title: 'Techfour DMS',
      theme: ThemeData(
        primarySwatch: Colors.blue, // You can customize your primary color
        fontFamily: 'Inter', // Set the default font family
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(), // Set LoginScreen as the initial screen
    );
  }
}
