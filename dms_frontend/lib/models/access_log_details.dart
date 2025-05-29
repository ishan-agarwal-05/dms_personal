
class Accesslog {
  final int? id; // bigint
  final int? envId; // int
  final String? url; // varchar(255)
  final String? method; // varchar(20)
  final String? requestBody; // text
  final String? requestHeader; // text
  final String? response; // text
  final String? status; // enum('Requested', 'Failed', 'Success')
  final String? ip; // varchar(20)
  final String? createdAt; // timestamp
  final String? updatedAt; // timestamp
  final int? createdBy; // int
  final int? updatedBy; // int
  final bool? deleted; // tinyint(1)

  Accesslog({
    this.id,
    this.envId,
    this.url,
    this.method,
    this.requestBody,
    this.requestHeader,
    this.response,
    this.status,
    this.ip,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deleted,
  });

  factory Accesslog.fromJson(Map<String, dynamic> json) {
    return Accesslog(
      id: (json['id'] as num?)?.toInt(), // bigint can be large, but int? should suffice for typical IDs
      envId: json['env_id'] as int?,
      url: json['url'] as String?,
      method: json['method'] as String?,
      requestBody: json['request_body'] as String?,
      requestHeader: json['request_header'] as String?,
      response: json['response'] as String?,
      status: json['status'] as String?,
      ip: json['ip'] as String?,
      createdAt: json['createdAt'] as String?, // Assuming backend sends formatted string
      updatedAt: json['updatedAt'] as String?, // Assuming backend sends formatted string
      createdBy: json['created_by'] as int?,
      updatedBy: json['updated_by'] as int?,
      deleted: (json['deleted'] as int?) == 1, // tinyint(1) to bool
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'env_id': envId,
      'url': url,
      'method': method,
      'request_body': requestBody,
      'request_header': requestHeader,
      'response': response,
      'status': status,
      'ip': ip,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deleted': deleted,
    };
  }
}
