// ui_for_user_list/lib/user_list_main.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_for_user_list/main_login.dart';
import 'dart:convert';
import 'package:ui_for_user_list/models/user_list.dart'; // Add this import (adjust path)

// Import other management screens
import 'package:ui_for_user_list/access_log_main.dart';
import 'package:ui_for_user_list/app_config_main.dart';
import 'package:ui_for_user_list/document_master_main.dart';
import 'package:ui_for_user_list/upload_files_main.dart';

import 'package:ui_for_user_list/models/user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _isDocumentManagementExpanded = true; // Keep expanded for initial view
  String? _selectedStatus;

  // TextEditingControllers for each search field
  final TextEditingController _idSearchController = TextEditingController();
  final TextEditingController _usernameSearchController =
      TextEditingController();
  final TextEditingController _firstNameSearchController =
      TextEditingController();
  final TextEditingController _lastNameSearchController =
      TextEditingController();
  final TextEditingController _emailSearchController = TextEditingController();
  final TextEditingController _mobileSearchController = TextEditingController();

  // Pagination State Variables
  int _currentPage = 1;
  final int _itemsPerPage = 5;
  List<User> _displayedUsers = [];

  // API related state variables
  bool _isLoading = false;
  String? _errorMessage;
  int _totalItems = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _applySearchFilters(); // Initial fetch when screen loads
  }

  @override
  void dispose() {
    _idSearchController.dispose();
    _usernameSearchController.dispose();
    _firstNameSearchController.dispose();
    _lastNameSearchController.dispose();
    _emailSearchController.dispose();
    _mobileSearchController.dispose();
    super.dispose();
  }

  // Helper method to retrieve the auth token - add this to each class
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // NEW: Method to fetch data from your Flask API
  Future<void> _fetchUsersFromApi() async {
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

    // Replace with your actual API URL
    const String apiUrl =
        'http://127.0.0.1:5000/admin/users/list'; // Adjust if your Flask server runs on a different IP/port

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
          'id': _idSearchController.text,
          'username': _usernameSearchController.text,
          'first_name': _firstNameSearchController.text,
          'last_name': _lastNameSearchController.text,
          'email': _emailSearchController.text,
          'mobile': _mobileSearchController.text,
          'status': _selectedStatus, // Send null if no status is selected
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Parse the list of users
        final List<dynamic> userDataList = responseData['data'];
        final List<User> fetchedUsers =
            userDataList.map((json) => User.fromJson(json)).toList();

        setState(() {
          _displayedUsers = fetchedUsers;
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
              'Failed to load users: ${errorData['error'] ?? response.statusCode}';
          _isLoading = false;
          _displayedUsers = []; // Clear users on error
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
        _displayedUsers = []; // Clear users on error
        _totalItems = 0;
        _totalPages = 0;
      });
    }
  }

  // --- Search Filtering Logic ---
  void _applySearchFilters() {
    _currentPage = 1; // Reset to first page on new search
    _fetchUsersFromApi(); // Now calls the API
  }

  // --- Pagination Logic Methods ---
  void _goToFirstPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage = 1;
        _fetchUsersFromApi();
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _fetchUsersFromApi();
      });
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _fetchUsersFromApi();
      });
    }
  }

  void _goToLastPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage = _totalPages;
        _fetchUsersFromApi();
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
                          'Users',
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
                            child: Center(child: CircularProgressIndicator()))
                      else if (_errorMessage != null)
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      else // Only show table if no loading/error
                        Expanded(
                          child: _buildUserTable(),
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

  // --- Build User Table (Minor Adjustments for User Model) ---
  Widget _buildUserTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '$_totalItems Users', // Display total count from API
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
                        color: Colors.grey.withOpacity(0.2), // Fixed withValues
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: DataTable(
                    columnSpacing: 30.0,
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
                            _buildSearchTextField(_idSearchController,
                                width: 50),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Username'),
                            const SizedBox(height: 5),
                            _buildSearchTextField(_usernameSearchController,
                                width: 120),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('First Name'),
                            const SizedBox(height: 5),
                            _buildSearchTextField(_firstNameSearchController,
                                width: 120),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Last Name'),
                            const SizedBox(height: 5),
                            _buildSearchTextField(_lastNameSearchController,
                                width: 120),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Email ID'),
                            const SizedBox(height: 5),
                            _buildSearchTextField(_emailSearchController,
                                width: 180),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mobile No.'),
                            const SizedBox(height: 5),
                            _buildSearchTextField(_mobileSearchController,
                                width: 120),
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
                            SizedBox(
                              width: 100,
                              height: 30,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedStatus,
                                  hint: Text('Select',
                                      style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13)),
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: Colors.grey),
                                  isDense: true,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedStatus = newValue;
                                      _applySearchFilters(); // Trigger API call
                                    });
                                  },
                                  items: <String>['Active', 'Inactive']
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
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
                                      horizontal: 10),
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
                    rows: _displayedUsers.map((user) {
                      // Use User object properties
                      return DataRow(
                        cells: [
                          DataCell(Text(user.id)),
                          DataCell(Text(user.username)),
                          DataCell(Text(user.firstName)),
                          DataCell(Text(user.lastName)),
                          DataCell(Text(user.email)),
                          DataCell(Text(user.mobile)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: user.status == 'Active'
                                    ? Colors.green
                                        .withOpacity(0.1) // Fixed withValues
                                    : Colors.red
                                        .withOpacity(0.1), // Fixed withValues
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                user.status,
                                style: TextStyle(
                                  color: user.status == 'Active'
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_red_eye_outlined,
                                      color: Colors.grey[600]),
                                  onPressed: () {
                // This is the navigation function that redirects to UserDetailsPage
                // It dynamically passes the user.id!
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserDetailsPage(userId: int.parse(user.id)),
                  ),
                );
                // Handle view action
                                  },
                                ),
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
      // Use _totalItems from API
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
                icon: Icon(Icons.first_page,
                    color: _currentPage == 1
                        ? Colors.grey[400]
                        : Colors.grey[600]),
                onPressed: _currentPage == 1 ? null : _goToFirstPage,
              ),
              IconButton(
                icon: Icon(Icons.chevron_left,
                    color: _currentPage == 1
                        ? Colors.grey[400]
                        : Colors.grey[600]),
                onPressed: _currentPage == 1 ? null : _goToPreviousPage,
              ),
              IconButton(
                icon: Icon(Icons.chevron_right,
                    color:
                        _currentPage == _totalPages // Use _totalPages from API
                            ? Colors.grey[400]
                            : Colors.grey[600]),
                onPressed: _currentPage == _totalPages ? null : _goToNextPage,
              ),
              IconButton(
                icon: Icon(Icons.last_page,
                    color:
                        _currentPage == _totalPages // Use _totalPages from API
                            ? Colors.grey[400]
                            : Colors.grey[600]),
                onPressed: _currentPage == _totalPages ? null : _goToLastPage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // AppBar, Drawer, and Helper Methods
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
              'Hi, Hr Admin',
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
            // Navigate to Dashboard (if it's a separate screen, otherwise do nothing)
            if (ModalRoute.of(context)?.settings.name != '/') {
              // Assuming dashboard is root
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (context) => const UserManagementScreen()),
              );
            }
          }),
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
              _buildSubDrawerItem(Icons.people, 'Users', onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => const UserManagementScreen()));
              }, isSelected: true), // Highlight current screen
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
              _buildSubDrawerItem(Icons.history, 'Access Logs', onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => const AccessLogsManagementScreen()));
              }),
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
    VoidCallback? onTap, // Added onTap
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
          ? Colors.blue.withOpacity(0.1) // Fixed withValues
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
    VoidCallback? onTap, // Added onTap
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
          ? Colors.blue.withOpacity(0.1) // Fixed withValues
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
          contentPadding:
              const EdgeInsets.symmetric(vertical: 5.0, horizontal: 0.0),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
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
