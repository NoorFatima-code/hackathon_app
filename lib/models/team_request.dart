import 'student.dart';

enum RequestStatus { pending, accepted, rejected, cancelled }

enum RequestDirection { sent, received }

class TeamRequest {
  final String id;
  final Student student; // sent: jisko bheji / received: jisne bheji
  final String message;
  final RequestDirection direction;
  final RequestStatus status;
  final DateTime createdAt;

  const TeamRequest({
    required this.id,
    required this.student,
    required this.message,
    required this.direction,
    required this.status,
    required this.createdAt,
  });

  TeamRequest copyWith({RequestStatus? status}) => TeamRequest(
        id: id,
        student: student,
        message: message,
        direction: direction,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'student': student.toJson(),
        'message': message,
        'direction': direction.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TeamRequest.fromJson(Map<String, dynamic> j) => TeamRequest(
        id: j['id'] as String,
        student: Student.fromJson(Map<String, dynamic>.from(j['student'])),
        message: j['message'] as String,
        direction: RequestDirection.values.byName(j['direction']),
        status: RequestStatus.values.byName(j['status']),
        createdAt: DateTime.parse(j['createdAt']),
      );
}