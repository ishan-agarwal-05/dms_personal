import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CommonDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? userName;

  const CommonDetailAppBar({
    super.key,
    this.userName,
  });

  Future<String?> _getUserNameFromToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? authToken = prefs.getString('authToken');
      
      if (authToken != null && authToken.isNotEmpty) {
        // Decode JWT token to extract firstName
        final parts = authToken.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          // Add padding if needed
          final normalizedPayload = payload.padRight(
              (payload.length + 3) & ~3, '=');
          final payloadMap = jsonDecode(
              utf8.decode(base64.decode(normalizedPayload)));
          return payloadMap['firstName'] ?? 'Admin';
        }
      }
    } catch (e) {
      // If token parsing fails, fall back to default
    }
    return userName ?? 'Admin';
  }

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(96.0),
      child: AppBar(
        backgroundColor: const Color(0xFFEBEDFF),
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/images/techfour.png',
                height: 50,
                width: 50,
              ),
              GestureDetector(
                onTap: () {
                  // Handle menu tap
                },
                child: const Icon(
                  Icons.menu,
                  size: 30,
                  color: Colors.black87,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.notifications_none, size: 28, color: Colors.black54),
                    const SizedBox(width: 10),
                    FutureBuilder<String?>(
                      future: _getUserNameFromToken(),
                      builder: (context, snapshot) {
                        final displayName = snapshot.data ?? 'Admin';
                        return Text(
                          'Hi, $displayName',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF252C70),
                            height: 1.2,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.person, size: 30, color: Colors.black54),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(96.0);
}