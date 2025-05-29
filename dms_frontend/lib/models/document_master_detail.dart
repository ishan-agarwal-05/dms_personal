
class DM {
  final int? id;
  final int? envId;
  final int? moduleId;
  final String? type;
  final String? allowedExtension;
  final int? allowedMaxSize;
  final String? filepath;
  final bool? isProtected;
  final bool? isDownloadable;
  final bool? isFilenameEncrypted;
  final String? backupDestination;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final int? createdBy;
  final int? updatedBy;
  final bool? deleted;

  DM({
    this.id,
    this.envId,
    this.moduleId,
    this.type,
    this.allowedExtension,
    this.allowedMaxSize,
    this.filepath,
    this.isProtected,
    this.isDownloadable,
    this.isFilenameEncrypted,
    this.backupDestination,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deleted,
  });

  factory DM.fromJson(Map<String, dynamic> json) {
    return DM(
      id: json['id'] as int?,
      envId: json['env_id'] as int?,
      moduleId: json['module_id'] as int?,
      type: json['type'] as String?,
      allowedExtension: json['allowed_extension'] as String?,
      allowedMaxSize: json['allowed_max_size'] as int?,
      filepath: json['filepath'] as String?,
      isProtected: (json['is_protected'] as int?) == 1, // tinyint(1) to bool
      isDownloadable: (json['is_downloadable'] as int?) == 1, // tinyint(1) to bool
      isFilenameEncrypted: (json['is_filename_encrypted'] as int?) == 1, // tinyint(1) to bool
      backupDestination: json['backup_destination'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String?, // Assuming backend sends formatted string
      updatedAt: json['updatedAt'] as String?, // Assuming backend sends formatted string
      createdBy: json['created_by'] as int?,
      updatedBy: json['updated_by'] as int?,
      deleted: (json['deleted'] as int?) == 1, // tinyint to bool
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'env_id': envId,
      'module_id': moduleId,
      'type': type,
      'allowed_extension': allowedExtension,
      'allowed_max_size': allowedMaxSize,
      'filepath': filepath,
      'is_protected': isProtected,
      'is_downloadable': isDownloadable,
      'is_filename_encrypted': isFilenameEncrypted,
      'backup_destination': backupDestination,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'deleted': deleted,
    };
  }
}
