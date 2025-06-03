import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? userName;
  final bool showNotifications;

  const CommonAppBar({
    super.key,
    this.userName,
    this.showNotifications = true,
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
          return payloadMap['first_name'] ?? 'Admin';
        }
      }
    } catch (e) {
      // If token parsing fails, fall back to default
    }
    return userName ?? 'Admin';
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.grey),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      title: Row(
        children: [
          Image.asset(
            "assets/images/techfour.png",
            width: 30,
            height: 30,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 10),
        ],
      ),
      actions: [
        if (showNotifications)
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.grey[700]),
            onPressed: () {
              // Handle notifications
            },
          ),
        const SizedBox(width: 10),
        FutureBuilder<String?>(
          future: _getUserNameFromToken(),
          builder: (context, snapshot) {
            final displayName = snapshot.data ?? 'Admin';
            return Row(
              children: [
                Text(
                  'Hi, $displayName',
                  style: TextStyle(color: Colors.grey[800], fontSize: 16),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
              ],
            );
          },
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}