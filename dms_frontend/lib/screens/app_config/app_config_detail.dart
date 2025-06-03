import 'package:flutter/material.dart';
import 'package:dms_frontend/models/detail/app_config_detail.dart';
import 'package:dms_frontend/services/api_service.dart';
import 'package:dms_frontend/widgets/common_app_bar.dart';
import 'package:dms_frontend/widgets/common_drawer.dart';
import 'dart:convert';

class AppConfigDetailsPage extends StatefulWidget {
  final int configId; // Accept configId as a parameter

  const AppConfigDetailsPage({super.key, required this.configId});

  @override
  State<AppConfigDetailsPage> createState() => _AppConfigDetailsPageState();
}

class _AppConfigDetailsPageState extends State<AppConfigDetailsPage> {
  Appconfig? _appConfigDetails;
  bool _isLoading = true;
  String _error = '';

  // Using centralized ApiService instead of dedicated service

  @override
  void initState() {
    super.initState();
    _fetchAppConfigDetails();
  }

  Future<void> _fetchAppConfigDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Use the centralized API service
      final response = await ApiService.instance.getAppConfigDetails(widget.configId);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final config = Appconfig.fromJson(responseData);
        if (mounted) {
          setState(() {
            _appConfigDetails = config;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load app config details: ${response.statusCode}');
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
      drawer: const CommonDrawer(selectedSection: DrawerSection.appConfig),
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
                  'App Configuration Details',
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
                } else if (_appConfigDetails == null) {
                  return const Center(child: Text('No app configuration details found.'));
                } else {
                  final Appconfig config = _appConfigDetails!;
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
                        // Form Rows matching the screenshot layout
                        _buildFormRow([
                          _buildFormGroup('Row ID', config.id?.toString() ?? 'N/A'),
                          _buildFormGroup('Env Name', config.env ?? 'N/A'),
                          _buildFormGroup('Code', config.code ?? 'N/A'),
                        ]),
                        _buildFormRow([
                          _buildFormGroup('API Configuration', config.appApiConfig ?? 'N/A'),
                          _buildFormGroup('Created by', config.createdBy ?? 'N/A'),
                          _buildFormGroup('Created Date & Time', config.createdAt ?? 'N/A'),
                        ]),
                        _buildFormRow([
                          _buildFormGroup('Modified by', config.updatedBy ?? 'N/A'),
                          _buildFormGroup('Modified Date & Time', config.updatedAt ?? 'N/A'),
                          _buildFormGroup('Deleted', config.deleted?.toString() ?? 'N/A'),
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

  // Helper methods

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
