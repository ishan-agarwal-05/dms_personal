// ui_for_user_list/lib/access_log_main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_for_user_list/main_login.dart';
import 'package:ui_for_user_list/models/access_log_details_screen.dart';
import 'dart:convert';
import 'models/access_log.dart'; // Import the NEW AccessLog model

// Import other management screens for drawer navigation
import 'package:ui_for_user_list/user_list_main.dart';
import 'package:ui_for_user_list/app_config_main.dart';
import 'package:ui_for_user_list/document_master_main.dart';
import 'package:ui_for_user_list/upload_files_main.dart';

class AccessLogsManagementScreen extends StatefulWidget {
  const AccessLogsManagementScreen({super.key});

  @override
  State<AccessLogsManagementScreen> createState() =>
      _AccessLogsManagementScreenState();
}

class _AccessLogsManagementScreenState
    extends State<AccessLogsManagementScreen> {
  bool _isDocumentManagementExpanded =
      true; // Renamed expansion state (consistent with others)

  // TextEditingControllers for each search field (updated for Access Logs)
  final TextEditingController _idSearchController = TextEditingController();
  final TextEditingController _envIdSearchController = TextEditingController();
  final TextEditingController _urlSearchController =
      TextEditingController(); // New: URL search
  final TextEditingController _methodSearchController =
      TextEditingController(); // New: Method search
  final TextEditingController _statusSearchController = TextEditingController();
  final TextEditingController _createdAtSearchController =
      TextEditingController();
  final TextEditingController _updatedAtSearchController =
      TextEditingController();

  // Pagination State Variables
  int _currentPage = 1;
  final int _itemsPerPage = 5;
  List<AccessLog> _displayedAccessLogs = []; // Change to List<AccessLog>

  // API related state variables
  bool _isLoading = false;
  String? _errorMessage;
  int _totalItems = 0; // Will be set by API response
  int _totalPages = 0; // Will be set by API response

  @override
  void initState() {
    super.initState();
    _applySearchFilters(); // Initial fetch when screen loads
  }

  @override
  void dispose() {
    _idSearchController.dispose();
    _envIdSearchController.dispose();
    _urlSearchController.dispose(); // Dispose new controller
    _methodSearchController.dispose(); // Dispose new controller
    _statusSearchController.dispose();
    _createdAtSearchController.dispose();
    _updatedAtSearchController.dispose();
    super.dispose();
  }

  // Helper method to retrieve the auth token - add this to each class
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }



  // Method to fetch data from your Flask API for Access Logs
  Future<void> _fetchAccessLogsFromApi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

  // Get the auth token first
  final String? authToken = await getAuthToken();
  
  if (authToken == null) {
    // Handle missing token
    setState(() {
      _errorMessage = 'Authentication token not found. Please log in again.';
      _isLoading = false;
    });

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    return;
  }

    // Replace with your actual API URL for access logs (port 5004 from Python refactor)
    const String apiUrl =
        'http://127.0.0.1:5000/admin/access_logs/list'; // <--- ADJUSTED THIS URL/PORT

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({
          'page': _currentPage,
          'limit': _itemsPerPage,
          // Send specific search parameters from your text controllers
          // Ensure these keys match what your Flask API expects for Access Logs
          'id': _idSearchController.text,
          'env_id': _envIdSearchController.text,
          'url': _urlSearchController.text, // New: URL search parameter
          'method':
              _methodSearchController.text, // New: Method search parameter
          'status': _statusSearchController.text,
          'created_at': _createdAtSearchController.text,
          'updated_at': _updatedAtSearchController.text,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Parse the list of access log entries
        final List<dynamic> accessLogDataList = responseData['data'];
        final List<AccessLog> fetchedAccessLogs =
            accessLogDataList.map((json) => AccessLog.fromJson(json)).toList();

        setState(() {
          _displayedAccessLogs = fetchedAccessLogs;
          _totalItems = responseData['totalItems'];
          _totalPages = responseData['totalPages'];
          _isLoading = false;
        });
      } else if (response.statusCode == 401){
        // Handle expired or invalid token
        setState(() {
          _errorMessage = 'Your session has expired. Please log in again.';
          _isLoading = false;
        });

        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    
      } else {
        // Handle API errors
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              'Failed to load access logs: ${errorData['error'] ?? response.statusCode}';
          _isLoading = false;
          _displayedAccessLogs = []; // Clear on error
          _totalItems = 0;
          _totalPages = 0;
        });
      }
    } catch (e) {
      // Handle network or parsing errors
      setState(() {
        _errorMessage =
            'Error: Could not connect to the server. ${e.toString()}';
        _isLoading = false;
        _displayedAccessLogs = []; // Clear on error
        _totalItems = 0;
        _totalPages = 0;
      });
    }
  }

  // --- Search Filtering Logic ---
  void _applySearchFilters() {
    _currentPage = 1; // Reset to first page on new search
    _fetchAccessLogsFromApi(); // Now calls the API
  }

  // --- Pagination Logic Methods ---
  void _goToFirstPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage = 1;
        _fetchAccessLogsFromApi();
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _fetchAccessLogsFromApi();
      });
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _fetchAccessLogsFromApi();
      });
    }
  }

  void _goToLastPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage = _totalPages;
        _fetchAccessLogsFromApi();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              if (constraints.maxWidth > 800)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Access Logs', // Updated title
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      // Display loading or error message
                      if (_isLoading)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_errorMessage != null)
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      else // Only show table if no loading/error
                        Expanded(
                          child: _buildAccessLogsTable(), // Changed method call
                        ),
                      _buildPagination(),
                      _buildCopyright(),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // --- Build Access Logs Table ---
  Widget _buildAccessLogsTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '$_totalItems Access Log Entries', // Display total count from API
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(
                            0.2), // Fixed withValues to withOpacity
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: DataTable(
                    columnSpacing: 20.0, // Adjusted column spacing
                    dataRowMaxHeight: 50.0,
                    headingRowHeight: 80.0,
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 15, 36, 100),
                    ),
                    columns: [
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ID'),
                            const SizedBox(height: 5),
                            _buildSearchTextField(
                              _idSearchController,
                              width: 60,
                            ),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Env ID'),
                            const SizedBox(height: 5),
                            _buildSearchTextField(
                              _envIdSearchController,
                              width: 80,
                            ),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('URL'), // New: URL column
                            const SizedBox(height: 5),
                            _buildSearchTextField(
                              _urlSearchController,
                              width: 150, // Adjust width as needed
                            ),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Method'), // New: Method column
                            const SizedBox(height: 5),
                            _buildSearchTextField(
                              _methodSearchController,
                              width: 100, // Adjust width as needed
                            ),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Status'),
                            const SizedBox(height: 5),
                            _buildSearchTextField(
                              _statusSearchController,
                              width: 100,
                            ),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Created At'),
                            const SizedBox(height: 5),
                            _buildSearchTextField(
                              _createdAtSearchController,
                              width: 140,
                            ),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Updated At'),
                            const SizedBox(height: 5),
                            _buildSearchTextField(
                              _updatedAtSearchController,
                              width: 140,
                            ),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Actions'),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 25,
                              child: ElevatedButton(
                                onPressed:
                                    _applySearchFilters, // Trigger API call
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  textStyle: const TextStyle(fontSize: 12),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('Search'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    rows: _displayedAccessLogs.map((accessLog) {
                      // Use AccessLog object properties
                      return DataRow(
                        cells: [
                          DataCell(Text(accessLog.id?.toString() ?? 'N/A')),
                          DataCell(Text(accessLog.envId?.toString() ?? 'N/A')),
                          DataCell(Text(accessLog.url ?? 'N/A')), // Display URL
                          DataCell(
                            Text(accessLog.method ?? 'N/A'),
                          ), // Display Method
                          DataCell(Text(accessLog.status ?? 'N/A')),
                          DataCell(
                            Text(
                              accessLog.createdAt?.toLocal().toString().split(
                                        ' ',
                                      )[0] ??
                                  'N/A',
                            ),
                          ),
                          DataCell(
                            Text(
                              accessLog.updatedAt?.toLocal().toString().split(
                                        ' ',
                                      )[0] ??
                                  'N/A',
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AccessLogDetailsPage(logId: accessLog.id!),
                  ),
                );
                                  },
                                ),
                                // You might add Edit/Delete buttons here too
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Pagination Widget (Adjusted to use _totalItems and _totalPages) ---
  Widget _buildPagination() {
    final int startIndex = (_currentPage - 1) * _itemsPerPage + 1;
    int endIndex = startIndex + _itemsPerPage - 1;
    if (endIndex > _totalItems) {
      endIndex = _totalItems;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Items per page: $_itemsPerPage',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(width: 20),
          Text(
            '$startIndex-$endIndex of $_totalItems', // Use _totalItems from API
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(width: 20),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.first_page,
                  color:
                      _currentPage == 1 ? Colors.grey[400] : Colors.grey[600],
                ),
                onPressed: _currentPage == 1 ? null : _goToFirstPage,
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color:
                      _currentPage == 1 ? Colors.grey[400] : Colors.grey[600],
                ),
                onPressed: _currentPage == 1 ? null : _goToPreviousPage,
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: _currentPage == _totalPages // Use _totalPages from API
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                onPressed: _currentPage == _totalPages ? null : _goToNextPage,
              ),
              IconButton(
                icon: Icon(
                  Icons.last_page,
                  color: _currentPage == _totalPages // Use _totalPages from API
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                onPressed: _currentPage == _totalPages ? null : _goToLastPage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- AppBar, Drawer, and Helper Methods (minor adjustments for drawer) ---
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.grey),
          onPressed: () {
            Scaffold.of(context).openDrawer(); // Opens the drawer
          },
        ),
      ),
      title: Row(
        children: [
          Image.asset(
            "assets/images/techfour.png", // Ensure this path is correct
            width: 30,
            height: 30,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 10),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_none, color: Colors.grey[700]),
          onPressed: () {
            // Handle notifications
          },
        ),
        const SizedBox(width: 10),
        Row(
          children: [
            Text(
              'Hi, Admin',
              style: TextStyle(color: Colors.grey[800], fontSize: 16),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
          ],
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(
                255,
                221,
                229,
                236,
              ), // Your existing background color
            ),
            child: Center(
              child: Image.asset(
                'assets/images/techfour.png', // <--- REPLACE WITH YOUR IMAGE PATH
                width: 150,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
          _buildDrawerItem(Icons.dashboard, 'Dashboard', onTap: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => const UserManagementScreen()));
          }),
          ExpansionTile(
            leading: Icon(Icons.folder_open, color: Colors.grey[700]),
            title: Text(
              'Document Management', // Kept generic for main category
              style: TextStyle(color: Colors.grey[700]),
            ),
            trailing: Icon(
              _isDocumentManagementExpanded // Use the new expansion state variable
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.grey[700],
            ),
            onExpansionChanged: (bool expanded) {
              setState(() {
                _isDocumentManagementExpanded =
                    expanded; // Update the new state variable
              });
            },
            initiallyExpanded:
                _isDocumentManagementExpanded, // Use the new state variable
            children: <Widget>[
              _buildSubDrawerItem(Icons.people, 'Users', onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => const UserManagementScreen()));
              }),
              _buildSubDrawerItem(Icons.settings, 'App Configuration',
                  onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => const AppConfigManagementScreen()));
              }),
              _buildSubDrawerItem(Icons.cloud_upload, 'Uploaded Files',
                  onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => const UploadedFileManagementScreen()));
              }),
              _buildSubDrawerItem(Icons.description, 'Document Master',
                  onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => const DocumentMasterManagementScreen()));
              }),
              // Highlight Access Logs
              _buildSubDrawerItem(
                Icons.history,
                'Access Logs',
                isSelected: true, // This item is now selected
                onTap: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => const AccessLogsManagementScreen()));
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
              // Clear the stored token
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('authToken');

              // Navigate to login screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
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
      tileColor: isSelected
          ? Colors.blue.withOpacity(0.1) // Fixed withValues to withOpacity
          : null,
      onTap: () {
        if (MediaQuery.of(context).size.width < 800) {
          Navigator.pop(context);
        }
        onTap?.call(); // Call the provided onTap callback
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
      tileColor: isSelected
          ? Colors.blue.withOpacity(0.1) // Fixed withValues to withOpacity
          : null,
      onTap: () {
        if (MediaQuery.of(context).size.width < 800) {
          Navigator.pop(context);
        }
        onTap?.call(); // Call the provided onTap callback
      },
    );
  }

  Widget _buildSearchTextField(
    TextEditingController controller, {
    double width = 120,
    TextAlign textAlign = TextAlign.start,
  }) {
    return SizedBox(
      width: width,
      height: 30,
      child: TextField(
        controller: controller,
        textAlign: textAlign,
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 5.0,
            horizontal: 0.0,
          ),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2.0,
            ),
          ),
        ),
        onSubmitted: (_) => _applySearchFilters(),
      ),
    );
  }

  Widget _buildCopyright() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          'Copyright © 2024 Techfour',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ),
    );
  }
}
