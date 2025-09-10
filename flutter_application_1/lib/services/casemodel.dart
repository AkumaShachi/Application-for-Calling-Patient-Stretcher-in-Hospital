// models/case_model.dart
class CaseModel {
  final int caseId;
  final String patientId;
  final String patientType;
  final String roomFrom;
  final String roomTo;
  final String status;
  final String createdAt;
  final String? completedAt;
  final String? notes;

  CaseModel({
    required this.caseId,
    required this.patientId,
    required this.patientType,
    required this.roomFrom,
    required this.roomTo,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.notes,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      caseId: json['case_id'],
      patientId: json['patient_id'] ?? '',
      patientType: json['patient_type'] ?? '',
      roomFrom: json['room_from'] ?? '',
      roomTo: json['room_to'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      completedAt: json['completed_at'],
      notes: json['notes'],
    );
  }
}
