import 'package:flutter/material.dart';
import 'package:dms_frontend/models/detail/user_detail.dart';
import 'package:dms_frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dms_frontend/widgets/common_app_bar.dart';
import 'package:dms_frontend/widgets/common_drawer.dart';
import 'dart:convert';

class UserDetailsPage extends StatefulWidget {
  final int userId; // Accept userId as a parameter

  const UserDetailsPage({super.key, required this.userId});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  UserD? _userDetails;
  bool _isLoading = true;
  String _error = '';


  // Method to retrieve the JWT token directly from SharedPreferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken'); // Use the same key as where it's stored during login
  }

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final String? token = await _getAuthToken(); // Get token using the local method

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please log in.');
      }

      // Use the centralized API service
      final response = await ApiService.instance.getUserDetails(widget.userId);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final user = UserD.fromJson(responseData);
        
        if (mounted) {
          setState(() {
            _userDetails = user;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load user details: ${response.statusCode}');
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
      drawer: const CommonDrawer(selectedSection: DrawerSection.users),
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
                const Text(
                  'User Details',
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
                } else if (_userDetails == null) {
                  return const Center(child: Text('No user details found.'));
                } else {
                  final UserD user = _userDetails!;
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
                        // Form Rows with _buildFormGroup, displaying 'user' values
                        _buildFormRow([
                          _buildFormGroup('First Name', user.firstName ?? 'N/A'),
                          _buildFormGroup('Middle Name', user.middleName ?? 'N/A'),
                          _buildFormGroup('Last Name', user.lastName ?? 'N/A'),
                        ]),
                        _buildFormRow([
                          _buildFormGroup('Username', user.username ?? 'N/A'),
                          _buildFormGroup('Email Address', user.email ?? 'N/A'),
                          _buildFormGroup('Mobile', user.mobile ?? 'N/A'),
                        ]),
                        _buildFormRow([
                          _buildFormGroup('Status', user.status ?? 'N/A'),
                          _buildFormGroup('Is Admin', user.isAdmin ?? 'N/A'),
                          _buildFormGroup('Web Access', user.webAccess ?? 'N/A'),
                        ]),
                        _buildFormRow([
                          _buildFormGroup('Mobile Access', user.mobileAccess ?? 'N/A'),
                          _buildFormGroup('Last Password Change', user.lastPasswordChange ?? 'N/A'),
                          _buildFormGroup('Created By', user.createdBy ?? 'N/A'),
                        ]),
                        _buildFormRow([
                          _buildFormGroup('Modified By', user.modifiedBy ?? 'N/A'),
                          _buildFormGroup('Deleted', user.deleted?.toString() ?? 'N/A'),
                          Container(),
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
      ),
    );
  }

  // Helper methods below here

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
