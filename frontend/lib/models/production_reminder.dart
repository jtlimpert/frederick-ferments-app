class ProductionReminder {
  final String id;
  final String batchId;
  final String reminderType;
  final String message;
  final DateTime dueAt;
  final DateTime? completedAt;
  final DateTime? snoozedUntil;
  final String? notes;
  final DateTime createdAt;

  ProductionReminder({
    required this.id,
    required this.batchId,
    required this.reminderType,
    required this.message,
    required this.dueAt,
    this.completedAt,
    this.snoozedUntil,
    this.notes,
    required this.createdAt,
  });

  bool get isCompleted => completedAt != null;
  bool get isSnoozed => snoozedUntil != null && DateTime.now().isBefore(snoozedUntil!);
  bool get isDue => !isCompleted && DateTime.now().isAfter(dueAt) && !isSnoozed;
  bool get isUpcoming => !isCompleted && DateTime.now().isBefore(dueAt);

  factory ProductionReminder.fromJson(Map<String, dynamic> json) {
    return ProductionReminder(
      id: json['id'] as String,
      batchId: json['batchId'] as String,
      reminderType: json['reminderType'] as String,
      message: json['message'] as String,
      dueAt: DateTime.parse(json['dueAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      snoozedUntil: json['snoozedUntil'] != null
          ? DateTime.parse(json['snoozedUntil'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchId': batchId,
      'reminderType': reminderType,
      'message': message,
      'dueAt': dueAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'snoozedUntil': snoozedUntil?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SnoozeReminderInput {
  final String reminderId;
  final DateTime snoozeUntil;

  SnoozeReminderInput({
    required this.reminderId,
    required this.snoozeUntil,
  });

  Map<String, dynamic> toJson() {
    return {
      'reminderId': reminderId,
      'snoozeUntil': snoozeUntil.toIso8601String(),
    };
  }
}

class CompleteReminderInput {
  final String reminderId;
  final String? notes;

  CompleteReminderInput({
    required this.reminderId,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'reminderId': reminderId,
      'notes': notes,
    };
  }
}

class ReminderResult {
  final bool success;
  final String message;

  ReminderResult({
    required this.success,
    required this.message,
  });

  factory ReminderResult.fromJson(Map<String, dynamic> json) {
    return ReminderResult(
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }
}
