// lib/screens/app_config_details_page.dart
import 'package:flutter/material.dart';
import 'package:ui_for_user_list/models/access_log_details.dart';
import 'package:ui_for_user_list/models/access_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:ui_for_user_list/main_login.dart';

class AccessLogDetailsPage extends StatefulWidget {
  final int logId; // Accept logId as a parameter

  const AccessLogDetailsPage({super.key, required this.logId});

  @override
  State<AccessLogDetailsPage> createState() => _AccessLogDetailsPageState();
}

class _AccessLogDetailsPageState extends State<AccessLogDetailsPage> {
  bool _isDocumentManagementExpanded = true;
  Accesslog? _accessLogDetails; // Changed model type to AccessLog
  bool _isLoading = true;
  String _error = '';

  final AccessLogService _accessLogService = AccessLogService(); // Changed service type

  // Method to retrieve the JWT token directly from SharedPreferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken'); // Use the same key as where it's stored during login
  }

  @override
  void initState() {
    super.initState();
    _fetchAccessLogDetails();
  }

  Future<void> _fetchAccessLogDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final String? token = await _getAuthToken(); // Get token using the local method

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      // Pass the dynamic logId from widget and the fetched token
      final log = await _accessLogService.fetchAccessLogDetails(widget.logId, token); // Use widget.logId and pass token
      if (mounted) {
        setState(() {
          _accessLogDetails = log;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
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
                  'assets/images/techfour.png', // Changed path to match UserDetailsPage
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
                const Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.notifications_none, size: 28, color: Colors.black54),
                      SizedBox(width: 10),
                      Text(
                        'Hi, Admin', // Remains 'Hi, Admin' as AccessLog doesn't have user name
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF252C70),
                          height: 1.2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.person, size: 30, color: Colors.black54),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          // Sidebar (copied from previous structure for consistency)
          Container(
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
                    // TODO: Navigate to Dashboard
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
                        Expanded(
                          child: Text(
                            'Document Management',
                            style: const TextStyle(
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
                    onTap: () {
                      // TODO: Navigate to Users Page
                    },
                  ),
                  _buildSubMenuItem(
                    icon: Icons.settings_applications,
                    text: 'App Configuration',
                    onTap: () {
                      // TODO: Navigate to App Configuration page
                    },
                  ),
                  _buildSubMenuItem(
                    icon: Icons.cloud_upload,
                    text: 'Uploaded Files',
                    onTap: () {
                      // TODO: Navigate to Uploaded Files page
                    },
                  ),
                  _buildSubMenuItem(
                    icon: Icons.description,
                    text: 'Document Master',
                    onTap: () {
                      // TODO: Navigate to Document Master
                    },
                  ),
                ],
                _buildSidebarItem(
                  icon: Icons.history,
                  text: 'Access Logs',
                  isActive: true, // Set active for this page
                  onTap: () {
                    _fetchAccessLogDetails(); // Re-fetch on click for testing
                  },
                ),
                const Spacer(),
                _buildSidebarItem(
                  icon: Icons.logout,
                  text: 'Logout',
                  isActive: false,
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('authToken'); // Use the correct key here too

                    // Navigate to login screen
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: const Icon(
                                Icons.arrow_back,
                                size: 24,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Access Log Details', // Changed Page Title
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF252C70),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0x1E767680),
                          ),
                        ),
                        // Display loading, error, or data
                        Builder(
                          builder: (context) {
                            if (_isLoading) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (_error.isNotEmpty) {
                              return Center(child: Text('Error: $_error'));
                            } else if (_accessLogDetails == null) { // Changed model type
                              return const Center(child: Text('No access log details found.')); // Changed message
                            } else {
                              final Accesslog log = _accessLogDetails!; // Changed model type
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(20),
                                margin: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'General Details',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    // Form Rows populated with AccessLog fields
                                    _buildFormRow([
                                      _buildFormGroup('Row ID', log.id?.toString() ?? 'N/A'),
                                      _buildFormGroup('Env ID', log.envId?.toString() ?? 'N/A'),
                                      _buildFormGroup('URL', log.url ?? 'N/A'),
                                    ]),
                                    _buildFormRow([
                                      _buildFormGroup('Method', log.method ?? 'N/A'),
                                      _buildFormGroup('Request Body', log.requestBody ?? 'N/A'),
                                      _buildFormGroup('Request Header', log.requestHeader ?? 'N/A'),
                                    ]),
                                    _buildFormRow([
                                      _buildFormGroup('Response', log.response ?? 'N/A'),
                                      _buildFormGroup('Status', log.status ?? 'N/A'),
                                      _buildFormGroup('IP', log.ip ?? 'N/A'),
                                    ]),
                                    _buildFormRow([
                                      _buildFormGroup('Created By', log.createdBy?.toString() ?? 'N/A'),
                                      _buildFormGroup('Created Date & Time', log.createdAt ?? 'N/A'),
                                      _buildFormGroup('Updated By', log.updatedBy?.toString() ?? 'N/A'),
                                    ]),
                                    _buildFormRow([
                                      _buildFormGroup('Updated Date & Time', log.updatedAt ?? 'N/A'),
                                      _buildFormGroup('Deleted', log.deleted == true ? 'Yes' : 'No'),
                                      const Expanded(child: SizedBox.shrink()), // Filler
                                    ]),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  height: 47,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0C000000),
                        offset: Offset(0, -2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Copyright © 2024 Techfour',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFA6A6A6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods (copied for consistency)

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
        padding: const EdgeInsets.fromLTRB(40, 10, 10, 10), // Indent for sub-menu
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

  Widget _buildFormRow(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.whereType<Widget>().map((widget) => Expanded(child: widget)).toList(),
      ),
    );
  }

  Widget _buildFormGroup(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0x66000000), // Greyed out label
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6), // Background for the value
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x19000000), width: 1),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF252C70), // Value text color
            ),
          ),
        ),
      ],
    );
  }
}
