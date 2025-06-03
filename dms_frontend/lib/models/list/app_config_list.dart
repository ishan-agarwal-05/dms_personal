// lib/models/app_config.dart
class AppConfig {
  final int? id; // Made nullable
  final String? env; // Made nullable
  final String? code; // Made nullable
  final String? appApiConfig; // Made nullable
  final DateTime? createdAt; // Added as nullable DateTime
  final DateTime? updatedAt; // Added as nullable DateTime

  AppConfig({
    this.id, // Made optional in constructor
    this.env, // Made optional in constructor
    this.code, // Made optional in constructor
    this.appApiConfig, // Made optional in constructor
    this.createdAt, // Added as optional
    this.updatedAt, // Added as optional
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      id: json['id'] as int?, // Safely cast to nullable int
      env: json['env'] as String?, // Safely cast to nullable String
      code: json['code'] as String?, // Safely cast to nullable String
      appApiConfig:
          json['app_api_config'] as String?, // Safely cast to nullable String
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(
              json['created_at'].toString(),
            ) // Safely parse to DateTime?, handle potential non-string
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(
              json['updated_at'].toString(),
            ) // Safely parse to DateTime?, handle potential non-string
          : null,
    );
  }
}
