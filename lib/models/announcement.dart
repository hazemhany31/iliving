import 'package:flutter/foundation.dart';
import '../utils/date_time_util.dart';

enum AnnouncementAudience {
  all,
  compoundResidents,
  buildingResidents,
  homeownersOnly,
  tenantsOnly,
}

@immutable
class Announcement {
  final String id;
  final String compoundId;
  final String? buildingId;
  final String title;
  final String titleAr;
  final String body;
  final String bodyAr;
  final AnnouncementAudience audience;
  final String authorUserId;
  final String? imageUrl;
  final bool isPinned;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.compoundId,
    this.buildingId,
    required this.title,
    this.titleAr = '',
    required this.body,
    this.bodyAr = '',
    this.audience = AnnouncementAudience.all,
    required this.authorUserId,
    this.imageUrl,
    this.isPinned = false,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String? ?? '',
      compoundId: json['compoundId'] as String? ?? '',
      buildingId: json['buildingId'] as String?,
      title: json['title'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? '',
      body: json['body'] as String? ?? '',
      bodyAr: json['bodyAr'] as String? ?? '',
      audience: AnnouncementAudience.values.firstWhere(
        (e) => e.name == json['audience'],
        orElse: () => AnnouncementAudience.all,
      ),
      authorUserId: json['authorUserId'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: DateTimeUtil.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'compoundId': compoundId,
      'buildingId': buildingId,
      'title': title,
      'titleAr': titleAr,
      'body': body,
      'bodyAr': bodyAr,
      'audience': audience.name,
      'authorUserId': authorUserId,
      'imageUrl': imageUrl,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Announcement copyWith({
    String? id,
    String? compoundId,
    String? buildingId,
    String? title,
    String? titleAr,
    String? body,
    String? bodyAr,
    AnnouncementAudience? audience,
    String? authorUserId,
    String? imageUrl,
    bool? isPinned,
    DateTime? createdAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      compoundId: compoundId ?? this.compoundId,
      buildingId: buildingId ?? this.buildingId,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      body: body ?? this.body,
      bodyAr: bodyAr ?? this.bodyAr,
      audience: audience ?? this.audience,
      authorUserId: authorUserId ?? this.authorUserId,
      imageUrl: imageUrl ?? this.imageUrl,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Announcement && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
