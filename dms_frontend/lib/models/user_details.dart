// lib/models/user.dart

class UserD {
  final int? id;
  final String? idStr;
  final int? roleId; // <--- Changed to int? as per DB schema
  final String? username;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? email;
  final String? mobile;
  final String? status;
  final String? isAdmin;
  final String? webAccess;
  final String? mobileAccess;
  final String? lastPasswordChange; // Datetime in DB, often sent as string in JSON
  final String? createdBy; // <--- Changed to String? for consistent display (can be int if you prefer)
  final String? modifiedBy; // <--- Changed to String? for consistent display (can be int if you prefer)
  final int? deleted;

  UserD({
    this.id,
    this.idStr,
    this.roleId,
    this.username,
    this.firstName,
    this.middleName,
    this.lastName,
    this.email,
    this.mobile,
    this.status,
    this.isAdmin,
    this.webAccess,
    this.mobileAccess,
    this.lastPasswordChange,
    this.createdBy,
    this.modifiedBy,
    this.deleted,
  });

  factory UserD.fromJson(Map<String, dynamic> json) {
    return UserD(
      id: json['id'] as int?,
      idStr: json['id_str']?.toString(), // Keep as String? as it's varchar
      roleId: json['role_id'] as int?, // <--- NOW CORRECTLY PARSED AS int?
      username: json['username'] as String?,
      firstName: json['first_name'] as String?,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      status: json['status'] as String?,
      isAdmin: json['is_admin'] as String?,
      webAccess: json['web_access'] as String?,
      mobileAccess: json['mobile_access'] as String?,
      // Datetime values typically come as strings in JSON.
      lastPasswordChange: json['last_password_change'] as String?,
      // created_by and modified_by are int in DB, but if your Flask sends them as strings or you want to display them as strings:
      createdBy: json['created_by']?.toString(),
      modifiedBy: json['modified_by']?.toString(),
      deleted: json['deleted'] as int?,
    );
  }

  // Optional: Method to convert a User object back to a JSON map (for sending data to API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_str': idStr,
      'role_id': roleId,
      'username': username,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'email': email,
      'mobile': mobile,
      'status': status,
      'is_admin': isAdmin,
      'web_access': webAccess,
      'mobile_access': mobileAccess,
      'last_password_change': lastPasswordChange,
      'created_by': createdBy,
      'modified_by': modifiedBy,
      'deleted': deleted,
    };
  }

  // Helper getters (unchanged)
  bool get isAdminBool => isAdmin == 'on';
  bool get hasWebAccess => webAccess == 'yes';
  bool get hasMobileAccess => mobileAccess == 'yes';
  bool get isDeleted => deleted == 1;
}