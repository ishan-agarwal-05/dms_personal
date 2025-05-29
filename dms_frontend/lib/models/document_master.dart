// lib/models/document_master.dart
class DocumentMaster {
  final int? id;
  final int? envId;
  final int? moduleId;
  final String? type;
  final String? status; // In DB it's enum, but String is fine for client model
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DocumentMaster({
    this.id,
    this.envId,
    this.moduleId,
    this.type,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory DocumentMaster.fromJson(Map<String, dynamic> json) {
    return DocumentMaster(
      id: json['id'] as int?,
      envId: json['env_id'] as int?, // Matches DB column name 'env_id'
      moduleId: json['module_id'] as int?, // Matches DB column name 'module_id'
      type: json['type'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  // Optional: Add a toJson method if you need to send DocumentMaster objects to your API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'env_id': envId,
      'module_id': moduleId,
      'type': type,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
