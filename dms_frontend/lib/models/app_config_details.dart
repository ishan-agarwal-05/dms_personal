// lib/models/app_config.dart

class Appconfig {
  final int? id;
  final String? env;
  final String? code;
  final String? appApiConfig; // This will be a JSON string from the backend
  final String? createdAt;
  final String? updatedAt;
  final String? createdBy; // Assuming it's sent as a string from backend
  final String? updatedBy; // Assuming it's sent as a string from backend
  final int? deleted; // Assuming it's sent as a boolean (0/1) from backend

  Appconfig({
    this.id,
    this.env,
    this.code,
    this.appApiConfig,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deleted,
  });

  factory Appconfig.fromJson(Map<String, dynamic> json) {
    return Appconfig(
      id: json['id'] as int?,
      env: json['env'] as String?,
      code: json['code'] as String?,
      // appApiConfig is a JSON string from the backend, so parse it if needed,
      // but for display, it's often fine as a raw string.
      appApiConfig: json['appApiConfig'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      createdBy: json['createdBy']?.toString(), // Ensure it's a string
      updatedBy: json['updatedBy']?.toString(), // Ensure it's a string
      deleted: json['deleted'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'env': env,
      'code': code,
      'appApiConfig': appApiConfig,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deleted': deleted,
    };
  }
}