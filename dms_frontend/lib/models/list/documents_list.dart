// lib/models/document.dart
class Document {
  final int? id;
  final int? envId;
  final String? type;
  final String? parentId;
  final String? refId;
  final int? moduleId;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Document({
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

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as int?,
      envId: json['env_id'] as int?,
      type: json['type'] as String?,
      parentId: json['parent_id'] as String?,
      refId: json['ref_id'] as String?,
      moduleId: json['module_id'] as int?,
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
