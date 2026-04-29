// UserRequestModel represents a pending user registration request.
//
// When a new teacher or chairperson wants access, they submit a request to
// Firestore.  The admin reviews it and either approves (creating their Firebase
// Auth account) or rejects it with a reason.
//
// Firestore collection: user_requests/{requestId}
//
// Status lifecycle:
//   pending  →  approved   (admin creates the Firebase Auth account)
//   pending  →  rejected   (admin stores a rejectionReason)

class UserRequestModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String employeeId;
  final String? clubId;
  final String? clubName;

  // FIX: New field — stores a free-text club name when the applicant's club
  // is not yet in the system.  Without this, chairpersons are completely
  // blocked from submitting if no clubs have been added yet.
  final String? unlistedClubName;

  final String status;
  final String? rejectionReason;

  // FIX: New field — the temporary password generated at approval time.
  // Stored on the request document so the admin can see it on the requests
  // screen and copy it to share with the new user.  Previously the password
  // was generated and immediately lost after the snackbar closed.
  final String? tempPassword;

  final DateTime createdAt;
  final DateTime? reviewedAt;

  const UserRequestModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.employeeId,
    this.clubId,
    this.clubName,
    this.unlistedClubName,
    required this.status,
    this.rejectionReason,
    this.tempPassword,
    required this.createdAt,
    this.reviewedAt,
  });

  factory UserRequestModel.fromJson(String id, Map<String, dynamic> json) {
    return UserRequestModel(
      id:               id,
      name:             (json['name']       as String?) ?? '',
      email:            (json['email']      as String?) ?? '',
      role:             (json['role']       as String?) ?? 'teacher',
      phone:            (json['phone']      as String?) ?? '',
      employeeId:       (json['employeeId'] as String?) ?? '',
      clubId:           json['clubId']           as String?,
      clubName:         json['clubName']         as String?,
      unlistedClubName: json['unlistedClubName'] as String?,
      status:           (json['status'] as String?) ?? 'pending',
      rejectionReason:  json['rejectionReason']  as String?,
      tempPassword:     json['tempPassword']      as String?,
      createdAt:  _parseDate(json['createdAt']),
      reviewedAt: _parseDate(json['reviewedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name':       name,
      'email':      email,
      'role':       role,
      'phone':      phone,
      'employeeId': employeeId,
      if (clubId           != null) 'clubId':           clubId,
      if (clubName         != null) 'clubName':         clubName,
      if (unlistedClubName != null) 'unlistedClubName': unlistedClubName,
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (tempPassword    != null) 'tempPassword':    tempPassword,
      'createdAt': createdAt,
      if (reviewedAt != null) 'reviewedAt': reviewedAt,
    };
  }

  UserRequestModel copyWith({
    String? status,
    String? rejectionReason,
    String? tempPassword,
    DateTime? reviewedAt,
  }) {
    return UserRequestModel(
      id:               id,
      name:             name,
      email:            email,
      role:             role,
      phone:            phone,
      employeeId:       employeeId,
      clubId:           clubId,
      clubName:         clubName,
      unlistedClubName: unlistedClubName,
      status:           status           ?? this.status,
      rejectionReason:  rejectionReason  ?? this.rejectionReason,
      tempPassword:     tempPassword     ?? this.tempPassword,
      createdAt:        createdAt,
      reviewedAt:       reviewedAt       ?? this.reviewedAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  try { return value.toDate(); } catch (_) {}
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
  
}
}