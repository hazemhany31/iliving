import 'package:flutter/foundation.dart';

@immutable
class InstallmentReminderSettings {
  final List<int> reminderDays;
  final bool autoRemindersEnabled;
  final DateTime? lastRunTimestamp;
  final DateTime updatedAt;
  final String updatedBy;

  const InstallmentReminderSettings({
    this.reminderDays = const [7, 3],
    this.autoRemindersEnabled = true,
    this.lastRunTimestamp,
    required this.updatedAt,
    this.updatedBy = 'Admin',
  });

  factory InstallmentReminderSettings.defaultSettings() {
    return InstallmentReminderSettings(
      reminderDays: const [7, 3],
      autoRemindersEnabled: true,
      updatedAt: DateTime.now(),
      updatedBy: 'System',
    );
  }

  factory InstallmentReminderSettings.fromJson(Map<String, dynamic> json) {
    final rawDays = json['reminderDays'] as List<dynamic>?;
    final parsedDays = rawDays != null
        ? rawDays.map((e) => (e as num).toInt()).toList()
        : const [7, 3];
    parsedDays.sort((a, b) => b.compareTo(a));

    return InstallmentReminderSettings(
      reminderDays: parsedDays.isEmpty ? const [7, 3] : parsedDays,
      autoRemindersEnabled: json['autoRemindersEnabled'] as bool? ?? true,
      lastRunTimestamp: json['lastRunTimestamp'] != null
          ? DateTime.parse(json['lastRunTimestamp'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      updatedBy: json['updatedBy'] as String? ?? 'Admin',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reminderDays': reminderDays,
      'autoRemindersEnabled': autoRemindersEnabled,
      'lastRunTimestamp': lastRunTimestamp?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  InstallmentReminderSettings copyWith({
    List<int>? reminderDays,
    bool? autoRemindersEnabled,
    DateTime? lastRunTimestamp,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return InstallmentReminderSettings(
      reminderDays: reminderDays ?? this.reminderDays,
      autoRemindersEnabled: autoRemindersEnabled ?? this.autoRemindersEnabled,
      lastRunTimestamp: lastRunTimestamp ?? this.lastRunTimestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallmentReminderSettings &&
          runtimeType == other.runtimeType &&
          listEquals(reminderDays, other.reminderDays) &&
          autoRemindersEnabled == other.autoRemindersEnabled;

  @override
  int get hashCode => Object.hash(Object.hashAll(reminderDays), autoRemindersEnabled);
}
