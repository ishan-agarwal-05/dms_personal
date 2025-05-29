import 'package:flutter/material.dart';
import 'package:ui_for_user_list/models/document_master_detail.dart'; // Corrected model import
import 'package:ui_for_user_list/models/document_master_detail_service.dart'; // Corrected service import path
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:ui_for_user_list/main_login.dart'; // Import LoginScreen for logout navigation

class DocumentMasterDetailsPage extends StatefulWidget {
  final int documentMasterId; // Accept documentMasterId as a parameter

  const DocumentMasterDetailsPage({super.key, required this.documentMasterId});

  @override
  State<DocumentMasterDetailsPage> createState() => _DocumentMasterDetailsPageState();
}

class _DocumentMasterDetailsPageState extends State<DocumentMasterDetailsPage> {
  bool _isDocumentManagementExpanded = true;
  DM? _documentMasterDetails; // Changed model type to DM
  bool _isLoading = true;
  String _error = '';

  final DocumentMasterService _documentMasterService = DocumentMasterService(); // Changed service type

  // Method to retrieve the JWT token directly from SharedPreferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken'); // Use the same key as where it's stored during login
  }

  @override
  void initState() {
    super.initState();
    _fetchDocumentMasterDetails();
  }

  Future<void> _fetchDocumentMasterDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final String? token = await _getAuthToken(); // Get token using the local method

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      // Pass the dynamic documentMasterId from widget and the fetched token
      final master = await _documentMasterService.fetchDocumentMasterDetails(widget.documentMasterId, token); // Use widget.documentMasterId and pass token
      if (mounted) {
        setState(() {
          _documentMasterDetails = master;
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
                  'assets/images/techfour.png', // Changed path to match other pages
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
                      const Text(
                        'Hi, Admin', // Remains 'Hi, Admin' as DocumentMaster doesn't have user name
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF252C70),
                          height: 1.2,
                        ),
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
                    isActive: true, // Set active for this page
                    onTap: () {
                      _fetchDocumentMasterDetails(); // Re-fetch on click for testing
                    },
                  ),
                ],
                _buildSidebarItem(
                  icon: Icons.history,
                  text: 'Access Logs',
                  onTap: () {
                    // TODO: Navigate to Access Logs
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
                              'Document Master Details', // Changed Page Title
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
                            } else if (_documentMasterDetails == null) { // Changed model type
                              return const Center(child: Text('No document master details found.')); // Changed message
                            } else {
                              final DM master = _documentMasterDetails!; // Changed model type to DM
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
                                    // Form Rows populated with DocumentMaster fields
                                    _buildFormRow([
                                      _buildFormGroup('Row ID', master.id?.toString() ?? 'N/A'),
                                      _buildFormGroup('Env ID', master.envId?.toString() ?? 'N/A'),
                                      _buildFormGroup('Module ID', master.moduleId?.toString() ?? 'N/A'),
                                    ]),
                                    _buildFormRow([
                                      _buildFormGroup('Type', master.type ?? 'N/A'),
                                      _buildFormGroup('Allowed Extension', master.allowedExtension ?? 'N/A'),
                                      _buildFormGroup('Allowed Max Size', master.allowedMaxSize?.toString() ?? 'N/A'),
                                    ]),
                                    _buildFormRow([
                                      _buildFormGroup('File Path', master.filepath ?? 'N/A'),
                                      _buildFormGroup('Is Protected', master.isProtected == true ? 'Yes' : 'No'),
                                      _buildFormGroup('Is Downloadable', master.isDownloadable == true ? 'Yes' : 'No'),
                                    ]),
                                    _buildFormRow([
                                      _buildFormGroup('Is Filename Encrypted', master.isFilenameEncrypted == true ? 'Yes' : 'No'),
                                      _buildFormGroup('Backup Destination', master.backupDestination ?? 'N/A'),
                                      _buildFormGroup('Status', master.status ?? 'N/A'),
                                    ]),
                                    _buildFormRow([
                                      _buildFormGroup('Created By', master.createdBy?.toString() ?? 'N/A'),
                                      _buildFormGroup('Created Date & Time', master.createdAt ?? 'N/A'),
                                      _buildFormGroup('Updated By', master.updatedBy?.toString() ?? 'N/A'),
                                    ]),
                                    _buildFormRow([
                                      _buildFormGroup('Updated Date & Time', master.updatedAt ?? 'N/A'),
                                      _buildFormGroup('Deleted', master.deleted == true ? 'Yes' : 'No'),
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
