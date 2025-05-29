// lib/models/uploaded_file.dart
class UploadedFile {
  final int? id;
  final int? envId;
  final String? type;
  final String? parentId;
  final String? refId;
  final int? moduleId;
  final String? status; // In DB it's enum, but String is fine for client model
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UploadedFile({
    this.id,
    this.envId,
    this.type,
    this.parentId,
    this.refId,
    this.moduleId,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory UploadedFile.fromJson(Map<String, dynamic> json) {
    return UploadedFile(
      id: json['id'] as int?,
      envId: json['env_id'] as int?, // Matches DB column name 'env_id'
      type: json['type'] as String?,
      parentId:
          json['parent_id'] as String?, // Matches DB column name 'parent_id'
      refId: json['ref_id'] as String?, // Matches DB column name 'ref_id'
      moduleId: json['module_id'] as int?, // Matches DB column name 'module_id'
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
