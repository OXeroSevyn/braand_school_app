class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String? assignedTo;
  final String createdBy;
  final String status;
  final int progress;
  final String? comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.assignedTo,
    required this.createdBy,
    required this.status,
    this.progress = 0,
    this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      assignedTo: json['assigned_to'] as String?,
      createdBy: json['created_by'] as String,
      status: json['status'] as String? ?? 'pending',
      progress: json['progress'] as int? ?? 0,
      comments: json['comments'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigned_to': assignedTo,
      'created_by': createdBy,
      'status': status,
      'progress': progress,
      'comments': comments,
    };
  }
}
