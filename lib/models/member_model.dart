// This class stores all the information for a club member.
// It is used to read member documents from Firestore and convert them to Dart objects.
class MemberModel {
  // Unique identifier of this member document
  final String id; // the document ID for this member

  // The club this member belongs to
  final String clubId; // the club ID that this member is a part of

  // The tenure this member belongs to
  final String tenureId; // the tenure ID for the member's current term

  // The member's full name
  final String name; // the member's name as a string

  // The member's PRN number
  final String prn; // the student's PRN identifier

  // Role in the club, such as "President" or "Member"
  final String position; // club position or role title

  // Current academic year of the member, from 1 to 4
  final int year; // year of study, like 1, 2, 3, or 4

  // Member's department, for example "Computer Engineering"
  final String department; // the academic department of the member

  // Member's phone number
  final String phone; // contact phone number for the member

  // Member's email address
  final String email; // email address (should end with @vit.edu)

  // True if the member is currently active in the club
  final bool isActive; // whether the member is active now

  // When this member record was created
  final DateTime createdAt; // the date/time when this record was created

  // Constructor for creating a new MemberModel object
  MemberModel({
    required this.id, // set the member document ID
    required this.clubId, // set the club ID
    required this.tenureId, // set the tenure ID
    required this.name, // set the name
    required this.prn, // set the PRN number
    required this.position, // set the role/position
    required this.year, // set the year of study
    required this.department, // set the department
    required this.phone, // set the phone number
    required this.email, // set the email address
    required this.isActive, // set whether active
    required this.createdAt, // set the created date/time
  });

  // Factory constructor to create a MemberModel from Firestore data.
  // It handles Firestore Timestamp values for the createdAt field.
  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] as String, // read id from Firestore map
      clubId: json['clubId'] as String, // read clubId from Firestore map
      tenureId: json['tenureId'] as String, // read tenureId from Firestore map
      name: json['name'] as String, // read name from Firestore map
      prn: json['prn'] as String, // read PRN from Firestore map
      position: json['position'] as String, // read position from Firestore map
      year: json['year'] as int, // read year from Firestore map
      department: json['department'] as String, // read department from Firestore map
      phone: json['phone'] as String, // read phone from Firestore map
      email: json['email'] as String, // read email from Firestore map
      isActive: json['isActive'] as bool, // read isActive from Firestore map
      createdAt: (json['createdAt'] as dynamic)?.toDate() as DateTime, // convert Firestore Timestamp to DateTime
    );
  }

  // Convert this MemberModel object to a JSON-compatible map.
  // This is useful when saving the member back to Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id, // include id in the JSON map
      'clubId': clubId, // include clubId in the JSON map
      'tenureId': tenureId, // include tenureId in the JSON map
      'name': name, // include name in the JSON map
      'prn': prn, // include prn in the JSON map
      'position': position, // include position in the JSON map
      'year': year, // include year in the JSON map
      'department': department, // include department in the JSON map
      'phone': phone, // include phone in the JSON map
      'email': email, // include email in the JSON map
      'isActive': isActive, // include isActive in the JSON map
      'createdAt': createdAt, // include createdAt in the JSON map
    };
  }
}
