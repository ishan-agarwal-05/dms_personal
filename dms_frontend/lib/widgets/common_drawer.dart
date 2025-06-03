import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dms_frontend/screens/auth/main_login.dart';
import 'package:dms_frontend/screens/users/users_list.dart';
import 'package:dms_frontend/screens/access_logs/access_logs_list.dart';
import 'package:dms_frontend/screens/app_config/app_config_list.dart';
import 'package:dms_frontend/screens/document_master/document_master_list.dart';
import 'package:dms_frontend/screens/documents/documents_list.dart';

enum DrawerSection {
  dashboard,
  users,
  appConfig,
  uploadedFiles,
  documentMaster,
  accessLogs,
}

class CommonDrawer extends StatefulWidget {
  final DrawerSection selectedSection;
  final bool isDocumentManagementExpanded;

  const CommonDrawer({
    super.key,
    required this.selectedSection,
    this.isDocumentManagementExpanded = true,
  });

  @override
  State<CommonDrawer> createState() => _CommonDrawerState();
}

class _CommonDrawerState extends State<CommonDrawer> {
  late bool _isDocumentManagementExpanded;

  @override
  void initState() {
    super.initState();
    _isDocumentManagementExpanded = widget.isDocumentManagementExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 221, 229, 236),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/techfour.png',
                width: 150,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
          _buildDrawerItem(
            Icons.dashboard,
            'Dashboard',
            isSelected: widget.selectedSection == DrawerSection.dashboard,
            onTap: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => const UserManagementScreen()));
            },
          ),
          ExpansionTile(
            leading: Icon(Icons.folder_open, color: Colors.grey[700]),
            title: Text(
              'Document Management',
              style: TextStyle(color: Colors.grey[700]),
            ),
            trailing: Icon(
              _isDocumentManagementExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.grey[700],
            ),
            onExpansionChanged: (bool expanded) {
              setState(() {
                _isDocumentManagementExpanded = expanded;
              });
            },
            initiallyExpanded: _isDocumentManagementExpanded,
            children: <Widget>[
              _buildSubDrawerItem(
                Icons.people,
                'Users',
                isSelected: widget.selectedSection == DrawerSection.users,
                onTap: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => const UserManagementScreen()));
                },
              ),
              _buildSubDrawerItem(
                Icons.settings,
                'App Configuration',
                isSelected: widget.selectedSection == DrawerSection.appConfig,
                onTap: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => const AppConfigListScreen()));
                },
              ),
              _buildSubDrawerItem(
                Icons.cloud_upload,
                'Documents',
                isSelected: widget.selectedSection == DrawerSection.uploadedFiles,
                onTap: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => const DocumentsListScreen()));
                },
              ),
              _buildSubDrawerItem(
                Icons.description,
                'Document Master',
                isSelected: widget.selectedSection == DrawerSection.documentMaster,
                onTap: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => const DocumentMasterListScreen()));
                },
              ),
              _buildSubDrawerItem(
                Icons.history,
                'Access Logs',
                isSelected: widget.selectedSection == DrawerSection.accessLogs,
                onTap: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => const AccessLogsListScreen()));
                },
              ),
            ],
          ),
          _buildDrawerItem(
            Icons.logout,
            'Logout',
            iconColor: Colors.redAccent,
            textColor: Colors.redAccent,
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('authToken');

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(
    IconData icon,
    String title, {
    bool isSelected = false,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? (isSelected ? Colors.blue : Colors.grey[700]),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? (isSelected ? Colors.blue : Colors.grey[700]),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
      onTap: () {
        if (MediaQuery.of(context).size.width < 800) {
          Navigator.pop(context);
        }
        onTap?.call();
      },
    );
  }

  ListTile _buildSubDrawerItem(
    IconData icon,
    String title, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56.0),
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
      onTap: () {
        if (MediaQuery.of(context).size.width < 800) {
          Navigator.pop(context);
        }
        onTap?.call();
      },
    );
  }
}