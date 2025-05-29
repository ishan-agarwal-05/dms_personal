
class Uploadedfile {
  final int? id;
  final int? envId;
  final String? parentId; // varchar(100), Nullable YES
  final String? refId; // varchar(100), Nullable YES
  final int? moduleId; // int, Nullable YES
  final String? type; // varchar(50), Nullable NO
  final String? filename; // text, Nullable NO
  final String? originalFileName; // varchar(255), Nullable NO
  final String? filePath; // text, Nullable NO
  final int? fileSize; // int, Nullable NO
  final String? extension; // varchar(200), Nullable YES
  final int? assignedTo; // int, Nullable YES
  final String? status; // enum, Nullable NO
  final bool? backupStatus; // tinyint, Nullable NO (0/1 to bool)
  final String? createdAt; // timestamp, Nullable YES
  final String? updatedAt; // timestamp, Nullable YES
  final int? createdBy; // int, Nullable NO

  // Note: 'updatedBy' and 'deleted' columns were not in the provided schema (image_f6235c.png)
  // so they are removed from this model.

  Uploadedfile({
    this.id,
    this.envId,
    this.parentId,
    this.refId,
    this.moduleId,
    this.type,
    this.filename,
    this.originalFileName,
    this.filePath,
    this.fileSize,
    this.extension,
    this.assignedTo,
    this.status,
    this.backupStatus,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory Uploadedfile.fromJson(Map<String, dynamic> json) {
    return Uploadedfile(
      id: json['id'] as int?,
      envId: json['env_id'] as int?,
      parentId: json['parent_id'] as String?,
      refId: json['ref_id'] as String?,
      moduleId: json['module_id'] as int?, // Changed to int?
      type: json['type'] as String?,
      filename: json['filename'] as String?,
      originalFileName: json['original_filename'] as String?,
      filePath: json['filepath'] as String?,
      fileSize: json['filesize'] as int?, // Changed to int?
      extension: json['extension'] as String?,
      assignedTo: json['assigned_to'] as int?, // Changed to int?
      status: json['status'] as String?,
      backupStatus: (json['backup_status'] as int?) == 1, // tinyint 0/1 to bool
      createdAt: json['createdAt'] as String?, // Assuming backend sends as string
      updatedAt: json['updatedAt'] as String?, // Assuming backend sends as string
      createdBy: json['created_by'] as int?, // Changed to int?
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'env_id': envId,
      'parent_id': parentId,
      'ref_id': refId,
      'module_id': moduleId,
      'type': type,
      'filename': filename,
      'original_filename': originalFileName,
      'filepath': filePath,
      'filesize': fileSize,
      'extension': extension,
      'assigned_to': assignedTo,
      'status': status,
      'backup_status': backupStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
    };
  }
}
