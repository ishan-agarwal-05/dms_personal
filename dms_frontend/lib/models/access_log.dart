// lib/models/access_log.dart
class AccessLog {
  final int? id;
  final int? envId;
  final String? url;
  final String? method;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AccessLog({
    this.id,
    this.envId,
    this.url,
    this.method,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create an AccessLog object from JSON
  factory AccessLog.fromJson(Map<String, dynamic> json) {
    return AccessLog(
      id: json['id'] as int?,
      envId: json['env_id'] as int?,
      url: json['url'] as String?,
      method: json['method'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  // Method to convert an AccessLog object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'env_id': envId,
      'url': url,
      'method': method,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
