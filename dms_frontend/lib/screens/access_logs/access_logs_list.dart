import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dms_frontend/screens/auth/main_login.dart';
import 'dart:convert';
import 'package:dms_frontend/models/list/access_log_list.dart';
import 'package:dms_frontend/screens/access_logs/access_logs_detail.dart';
import 'package:dms_frontend/widgets/common_app_bar.dart';
import 'package:dms_frontend/widgets/common_drawer.dart';
import 'package:dms_frontend/widgets/common_pagination.dart';
import 'package:dms_frontend/services/api_service.dart';

class AccessLogsListScreen extends StatefulWidget {
  const AccessLogsListScreen({super.key});

  @override
  State<AccessLogsListScreen> createState() => _AccessLogsListScreenState();
}

class _AccessLogsListScreenState extends State<AccessLogsListScreen> {
  // TextEditingControllers for each search field
  final TextEditingController _idSearchController = TextEditingController();
  final TextEditingController _envIdSearchController = TextEditingController();
  final TextEditingController _urlSearchController = TextEditingController();
  final TextEditingController _methodSearchController = TextEditingController();
  final TextEditingController _statusSearchController = TextEditingController();
  final TextEditingController _createdAtSearchController = TextEditingController();
  final TextEditingController _updatedAtSearchController = TextEditingController();

  // Pagination State Variables
  int _currentPage = 1;
  final int _itemsPerPage = 5;
  List<AccessLog> _displayedAccessLogs = [];

  // API related state variables
  bool _isLoading = false;
  String? _errorMessage;
  int _totalItems = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _applySearchFilters();
  }

  @override
  void dispose() {
    _idSearchController.dispose();
    _envIdSearchController.dispose();
    _urlSearchController.dispose();
    _methodSearchController.dispose();
    _statusSearchController.dispose();
    _createdAtSearchController.dispose();
    _updatedAtSearchController.dispose();
    super.dispose();
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> _fetchAccessLogsFromApi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
      // Create filters map for the API service
      final Map<String, dynamic> filters = {};
      if (_idSearchController.text.isNotEmpty) filters['id'] = _idSearchController.text;
      if (_envIdSearchController.text.isNotEmpty) filters['env_id'] = _envIdSearchController.text;
      if (_urlSearchController.text.isNotEmpty) filters['url'] = _urlSearchController.text;
      if (_methodSearchController.text.isNotEmpty) filters['method'] = _methodSearchController.text;
      if (_statusSearchController.text.isNotEmpty) filters['status'] = _statusSearchController.text;
      if (_createdAtSearchController.text.isNotEmpty) filters['created_at'] = _createdAtSearchController.text;
      if (_updatedAtSearchController.text.isNotEmpty) filters['updated_at'] = _updatedAtSearchController.text;

      final response = await ApiService.instance.getAccessLogsList(
        page: _currentPage,
        limit: _itemsPerPage,
        filters: filters.isNotEmpty ? filters : null,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> accessLogDataList = responseData['data'];
        final List<AccessLog> fetchedAccessLogs = accessLogDataList.map((json) => AccessLog.fromJson(json)).toList();

        setState(() {
          _displayedAccessLogs = fetchedAccessLogs;
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
          _errorMessage = 'Failed to load access logs: ${errorData['error'] ?? response.statusCode}';
          _isLoading = false;
          _displayedAccessLogs = [];
          _totalItems = 0;
          _totalPages = 0;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: Could not connect to the server. ${e.toString()}';
        _isLoading = false;
        _displayedAccessLogs = [];
        _totalItems = 0;
        _totalPages = 0;
      });
    }
  }

  void _applySearchFilters() {
    _currentPage = 1;
    _fetchAccessLogsFromApi();
  }

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
      appBar: const CommonAppBar(),
      drawer: const CommonDrawer(selectedSection: DrawerSection.accessLogs),
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
                        'Access Logs',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
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
                    else
                      Expanded(
                        child: _buildAccessLogTable(),
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

  Widget _buildAccessLogTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '$_totalItems Access Logs',
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
                    columnSpacing: 20.0,
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
                            const Text('URL'),
                            const SizedBox(height: 5),
                            _buildSearchTextField(
                              _urlSearchController,
                              width: 200,
                            ),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Method'),
                            const SizedBox(height: 5),
                            _buildSearchTextField(
                              _methodSearchController,
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
                            const Text('Status'),
                            const SizedBox(height: 5),
                            _buildSearchTextField(
                              _statusSearchController,
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
                                onPressed: _applySearchFilters,
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
                      return DataRow(
                        cells: [
                          DataCell(Text(accessLog.id?.toString() ?? 'N/A')),
                          DataCell(Text(accessLog.envId?.toString() ?? 'N/A')),
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(
                                accessLog.url ?? 'N/A',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(accessLog.method ?? 'N/A')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accessLog.status == '200'
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                accessLog.status ?? 'N/A',
                                style: TextStyle(
                                  color: accessLog.status == '200' ? Colors.green : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              accessLog.createdAt?.toLocal().toString().split(' ')[0] ?? 'N/A',
                            ),
                          ),
                          DataCell(
                            Text(
                              accessLog.updatedAt?.toLocal().toString().split(' ')[0] ?? 'N/A',
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
}