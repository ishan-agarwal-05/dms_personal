import 'package:flutter/material.dart';
import 'package:dms_frontend/models/detail/document_master_detail.dart';
import 'package:dms_frontend/services/api_service.dart';
import 'package:dms_frontend/widgets/common_app_bar.dart';
import 'package:dms_frontend/widgets/common_drawer.dart';
import 'dart:convert';

class DocumentMasterDetailsPage extends StatefulWidget {
  final int documentMasterId; // Accept documentMasterId as a parameter

  const DocumentMasterDetailsPage({super.key, required this.documentMasterId});

  @override
  State<DocumentMasterDetailsPage> createState() => _DocumentMasterDetailsPageState();
}

class _DocumentMasterDetailsPageState extends State<DocumentMasterDetailsPage> {
  DM? _documentMasterDetails;
  bool _isLoading = true;
  String _error = '';

  // Using centralized ApiService instead of dedicated service

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
      // Use the centralized API service
      final response = await ApiService.instance.getDocumentMasterDetails(widget.documentMasterId);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final master = DM.fromJson(responseData);
        if (mounted) {
          setState(() {
            _documentMasterDetails = master;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load document master details: ${response.statusCode}');
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
      drawer: const CommonDrawer(selectedSection: DrawerSection.documentMaster),
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
                  'Document Master Details',
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
                } else if (_documentMasterDetails == null) {
                  return const Center(child: Text('No document master details found.'));
                } else {
                  final DM master = _documentMasterDetails!;
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
