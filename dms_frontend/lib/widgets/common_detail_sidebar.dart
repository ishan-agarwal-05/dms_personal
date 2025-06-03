import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dms_frontend/screens/auth/main_login.dart';
import 'package:dms_frontend/screens/users/users_list.dart';
import 'package:dms_frontend/screens/access_logs/access_logs_list.dart';
import 'package:dms_frontend/screens/app_config/app_config_list.dart';
import 'package:dms_frontend/screens/document_master/document_master_list.dart';
import 'package:dms_frontend/screens/documents/documents_list.dart';

enum DetailSidebarSection {
  users,
  appConfig,
  uploadedFiles,
  documentMaster,
  accessLogs,
}

class CommonDetailSidebar extends StatefulWidget {
  final DetailSidebarSection selectedSection;
  final bool isDocumentManagementExpanded;

  const CommonDetailSidebar({
    super.key,
    required this.selectedSection,
    this.isDocumentManagementExpanded = true,
  });

  @override
  State<CommonDetailSidebar> createState() => _CommonDetailSidebarState();
}

class _CommonDetailSidebarState extends State<CommonDetailSidebar> {
  late bool _isDocumentManagementExpanded;

  @override
  void initState() {
    super.initState();
    _isDocumentManagementExpanded = widget.isDocumentManagementExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 233,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x19000000), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height - 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSidebarItem(
            icon: Icons.dashboard,
            text: 'Dashboard',
            onTap: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => const UserManagementScreen()));
            },
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isDocumentManagementExpanded = !_isDocumentManagementExpanded;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  const Icon(Icons.folder_open, size: 20, color: Colors.black54),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Document Management',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xB2000000),
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isDocumentManagementExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          if (_isDocumentManagementExpanded) ...[
            _buildSubMenuItem(
              icon: Icons.people,
              text: 'Users',
              isActive: widget.selectedSection == DetailSidebarSection.users,
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => const UserManagementScreen()));
              },
            ),
            _buildSubMenuItem(
              icon: Icons.settings_applications,
              text: 'App Configuration',
              isActive: widget.selectedSection == DetailSidebarSection.appConfig,
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => const AppConfigListScreen()));
              },
            ),
            _buildSubMenuItem(
              icon: Icons.cloud_upload,
              text: 'Documents',
              isActive: widget.selectedSection == DetailSidebarSection.uploadedFiles,
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => const DocumentsListScreen()));
              },
            ),
            _buildSubMenuItem(
              icon: Icons.description,
              text: 'Document Master',
              isActive: widget.selectedSection == DetailSidebarSection.documentMaster,
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => const DocumentMasterListScreen()));
              },
            ),
            _buildSubMenuItem(
              icon: Icons.history,
              text: 'Access Logs',
              isActive: widget.selectedSection == DetailSidebarSection.accessLogs,
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => const AccessLogsListScreen()));
              },
            ),
          ],
          const Spacer(),
          _buildSidebarItem(
            icon: Icons.logout,
            text: 'Logout',
            isActive: false,
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

  Widget _buildSidebarItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEBEDFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFF252C70) : Colors.black54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive ? const Color(0xFF252C70) : const Color(0xB2000000),
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEBEDFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.fromLTRB(40, 10, 10, 10),
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFF252C70) : Colors.black54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive ? const Color(0xFF252C70) : const Color(0xB2000000),
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}