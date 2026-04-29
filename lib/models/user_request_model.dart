// the data shape for a pending registration

// UserRequestModel represents a pending user registration request.
//
// When a new teacher or chairperson wants access to the app, they cannot
// register themselves — they submit a request document to Firestore instead.
// The admin reviews it and either approves (creating their Firebase account)
// or rejects it with a reason.
//
// Firestore collection: user_requests/{requestId}
//
// Status lifecycle:
//   pending  →  approved   (admin creates the Firebase Auth account)
//   pending  →  rejected   (admin stores a rejectionReason)

class UserRequestModel {
  final String id;           // Firestore document ID
  final String name;         // Applicant's full name
  final String email;        // Email they want to use for login
  final String role;         // 'teacher' or 'chairperson'
  final String phone;        // Contact number
  final String employeeId;   // VIT employee / staff ID
  final String? clubId;      // Set when an existing club is selected, or written back after new club is created
  final String? clubName;    // Human-readable club name for the admin UI
  final String status;       // 'pending' | 'approved' | 'rejected'
  final String? rejectionReason; // Set by admin on rejection
  final DateTime createdAt;  // When the request was submitted
  final DateTime? reviewedAt; // When the admin acted on it
  final String? tempPassword; // Stored after approval so admin can retrieve it later

  // newClubData is populated when a chairperson selects "Register a new club".
  // It holds the minimal fields needed to create a ClubModel document on approval.
  // Once the club is created, its Firestore ID is written back to clubId.
  final Map<String, dynamic>? newClubData;

  const UserRequestModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.employeeId,
    this.clubId,
    this.clubName,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
    this.tempPassword,
    this.newClubData,
  });

  // Convert Firestore document data into a UserRequestModel.
  // The document ID is passed separately because Firestore does not include
  // it inside the data map.
  factory UserRequestModel.fromJson(String id, Map<String, dynamic> json) {
    return UserRequestModel(
      id: id,
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'teacher',
      phone: (json['phone'] as String?) ?? '',
      employeeId: (json['employeeId'] as String?) ?? '',
      clubId: json['clubId'] as String?,
      clubName: json['clubName'] as String?,
      status: (json['status'] as String?) ?? 'pending',
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      reviewedAt: (json['reviewedAt'] as dynamic)?.toDate(),
      tempPassword: json['tempPassword'] as String?,
      newClubData: json['newClubData'] as Map<String, dynamic>?,
    );
  }

  // Convert a UserRequestModel back into a Map for writing to Firestore.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'employeeId': employeeId,
      if (clubId != null) 'clubId': clubId,
      if (clubName != null) 'clubName': clubName,
      if (newClubData != null) 'newClubData': newClubData, // ADD THIS
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (tempPassword != null) 'tempPassword': tempPassword, // ADD THIS
      'createdAt': createdAt,
      if (reviewedAt != null) 'reviewedAt': reviewedAt,
    };
  }

  // copyWith lets us create a modified copy without mutating the original.
  // Used in the controller when updating status, rejectionReason, etc.

UserRequestModel copyWith({
  String? status,
  String? rejectionReason,
  DateTime? reviewedAt,
  String? tempPassword,
  String? clubId,
  String? clubName,
  Map<String, dynamic>? newClubData,
}) {
  return UserRequestModel(
    id: id,
    name: name,
    email: email,
    role: role,
    phone: phone,
    employeeId: employeeId,
    clubId: clubId ?? this.clubId,
    clubName: clubName ?? this.clubName,
    status: status ?? this.status,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    createdAt: createdAt,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    tempPassword: tempPassword ?? this.tempPassword,
    newClubData: newClubData ?? this.newClubData,
  );
  }
}