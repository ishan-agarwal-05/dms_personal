import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dms_frontend/screens/auth/main_login.dart';
import 'dart:convert';
import 'package:dms_frontend/models/list/user_list.dart';
import 'package:dms_frontend/screens/users/users_detail.dart';
import 'package:dms_frontend/widgets/common_app_bar.dart';
import 'package:dms_frontend/widgets/common_drawer.dart';
import 'package:dms_frontend/widgets/common_pagination.dart';
import 'package:dms_frontend/widgets/common_search_field.dart';
import 'package:dms_frontend/services/api_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
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

  // Method to fetch data from API using the centralized service
  Future<void> _fetchUsersFromApi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check if auth token exists
    final String? authToken = await getAuthToken();
    
    if (authToken == null) {
      setState(() {
        _errorMessage = 'Authentication token not found. Please log in again.';
        _isLoading = false;
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
      return;
    }

    try {
      // Use the centralized API service
      final response = await ApiService.instance.getUsersList(
        page: _currentPage,
        limit: _itemsPerPage,
        id: _idSearchController.text.isNotEmpty ? _idSearchController.text : null,
        username: _usernameSearchController.text.isNotEmpty ? _usernameSearchController.text : null,
        firstName: _firstNameSearchController.text.isNotEmpty ? _firstNameSearchController.text : null,
        lastName: _lastNameSearchController.text.isNotEmpty ? _lastNameSearchController.text : null,
        email: _emailSearchController.text.isNotEmpty ? _emailSearchController.text : null,
        mobile: _mobileSearchController.text.isNotEmpty ? _mobileSearchController.text : null,
        status: _selectedStatus,
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

        if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
    
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
      appBar: const CommonAppBar(),
      drawer: const CommonDrawer(selectedSection: DrawerSection.users),
      backgroundColor: Colors.grey[50],
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
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
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1400),
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
                        color: Colors.grey.withValues(alpha: 0.2),
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
                            CommonSearchField(
                              controller: _idSearchController,
                              width: 50,
                              onSubmitted: _applySearchFilters,
                            ),
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
                            CommonSearchField(
                              controller: _usernameSearchController,
                              width: 120,
                              onSubmitted: _applySearchFilters,
                            ),
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
                            CommonSearchField(
                              controller: _firstNameSearchController,
                              width: 120,
                              onSubmitted: _applySearchFilters,
                            ),
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
                            CommonSearchField(
                              controller: _lastNameSearchController,
                              width: 120,
                              onSubmitted: _applySearchFilters,
                            ),
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
                            CommonSearchField(
                              controller: _emailSearchController,
                              width: 180,
                              onSubmitted: _applySearchFilters,
                            ),
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
                            CommonSearchField(
                              controller: _mobileSearchController,
                              width: 120,
                              onSubmitted: _applySearchFilters,
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
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
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
          const SizedBox(height: 16),
          CommonPagination(
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalItems: _totalItems,
            itemsPerPage: _itemsPerPage,
            onFirstPage: _goToFirstPage,
            onPreviousPage: _goToPreviousPage,
            onNextPage: _goToNextPage,
            onLastPage: _goToLastPage,
          ),
        ],
        ),
      ),
    );
  }

}
