import 'package:flutter/material.dart';
import 'package:dms_frontend/widgets/common_app_bar.dart';
import 'package:dms_frontend/widgets/common_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dms_frontend/screens/auth/main_login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GenericDetailScreen<T> extends StatefulWidget {
  final String title;
  final DrawerSection drawerSection;
  final int itemId;
  final Future<http.Response> Function(int id) apiCall;
  final T Function(Map<String, dynamic> json) fromJson;
  final Widget Function(T item) buildContent;
  
  const GenericDetailScreen({
    super.key,
    required this.title,
    required this.drawerSection,
    required this.itemId,
    required this.apiCall,
    required this.fromJson,
    required this.buildContent,
  });

  @override
  State<GenericDetailScreen<T>> createState() => _GenericDetailScreenState<T>();
}

class _GenericDetailScreenState<T> extends State<GenericDetailScreen<T>> {
  T? _itemDetails;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchItemDetails();
  }

  // Helper method to retrieve the auth token
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> _fetchItemDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final String? token = await getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      final response = await widget.apiCall(widget.itemId);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final item = widget.fromJson(responseData);
        
        if (mounted) {
          setState(() {
            _itemDetails = item;
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Your session has expired. Please log in again.';
          _isLoading = false;
        });

        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      } else {
        throw Exception('Failed to load ${widget.title.toLowerCase()} details: ${response.statusCode}');
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
      appBar: const CommonAppBar(),
      drawer: CommonDrawer(selectedSection: widget.drawerSection),
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
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
                    Text(
                      widget.title,
                      style: const TextStyle(
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
                    } else if (_itemDetails == null) {
                      return Center(child: Text('No ${widget.title.toLowerCase()} details found.'));
                    } else {
                      final details = _itemDetails;
                      if (details != null) {
                        return widget.buildContent(details);
                      } else {
                        return Center(child: Text('No ${widget.title.toLowerCase()} details found.'));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}