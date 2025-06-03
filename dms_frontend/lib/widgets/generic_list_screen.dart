import 'package:flutter/material.dart';
import 'package:dms_frontend/widgets/common_app_bar.dart';
import 'package:dms_frontend/widgets/common_drawer.dart';
import 'package:dms_frontend/widgets/common_pagination.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dms_frontend/screens/auth/main_login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GenericListScreen<T> extends StatefulWidget {
  final String title;
  final DrawerSection drawerSection;
  final Future<http.Response> Function(int page, int limit, Map<String, dynamic>? filters) apiCall;
  final T Function(Map<String, dynamic> json) fromJson;
  final List<DataColumn> Function() buildColumns;
  final List<DataCell> Function(T item) buildCells;
  final Widget Function(T item)? onItemTap;
  
  const GenericListScreen({
    super.key,
    required this.title,
    required this.drawerSection,
    required this.apiCall,
    required this.fromJson,
    required this.buildColumns,
    required this.buildCells,
    this.onItemTap,
  });

  @override
  State<GenericListScreen<T>> createState() => _GenericListScreenState<T>();
}

class _GenericListScreenState<T> extends State<GenericListScreen<T>> {
  // Pagination State Variables
  int _currentPage = 1;
  final int _itemsPerPage = 5;
  List<T> _displayedItems = [];

  // API related state variables
  bool _isLoading = false;
  String? _errorMessage;
  int _totalItems = 0;
  int _totalPages = 0;

  // Search filters - can be customized per screen
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    _fetchDataFromApi();
  }

  // Helper method to retrieve the auth token
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Generic method to fetch data from API
  Future<void> _fetchDataFromApi() async {
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
      final response = await widget.apiCall(_currentPage, _itemsPerPage, _filters.isNotEmpty ? _filters : null);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Parse the list of items
        final List<dynamic> itemDataList = responseData['data'];
        final List<T> fetchedItems = itemDataList.map((json) => widget.fromJson(json)).toList();

        setState(() {
          _displayedItems = fetchedItems;
          _totalItems = responseData['totalItems'];
          _totalPages = responseData['totalPages'];
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Your session has expired. Please log in again.';
          _isLoading = false;
        });

        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = 'Failed to load ${widget.title.toLowerCase()}: ${errorData['error'] ?? response.statusCode}';
          _isLoading = false;
          _displayedItems = [];
          _totalItems = 0;
          _totalPages = 0;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: Could not connect to the server. ${e.toString()}';
        _isLoading = false;
        _displayedItems = [];
        _totalItems = 0;
        _totalPages = 0;
      });
    }
  }

  // Pagination Methods
  void _goToFirstPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage = 1;
        _fetchDataFromApi();
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _fetchDataFromApi();
      });
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _fetchDataFromApi();
      });
    }
  }

  void _goToLastPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage = _totalPages;
        _fetchDataFromApi();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      drawer: CommonDrawer(selectedSection: widget.drawerSection),
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                if (_isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (_errorMessage != null)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: _buildDataTable(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '$_totalItems ${widget.title}',
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
                    columns: widget.buildColumns(),
                    rows: _displayedItems.map((item) {
                      return DataRow(
                        cells: widget.buildCells(item),
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
    );
  }
}