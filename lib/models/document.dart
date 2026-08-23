import 'package:flutter/foundation.dart';

enum DocumentCategory {
  contract,
  receipt,
  clearance,
  blueprint,
  kyc,
  warranty,
  general,
}

@immutable
class DocumentItem {
  final String id;
  final String title;
  final String? description;
  final DocumentCategory category;
  final String fileUrl;
  final String fileExtension;
  final int fileSizeBytes;
  final String? ownerUserId;
  final String? associatedUnitId;
  final DateTime createdAt;

  const DocumentItem({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.fileUrl,
    this.fileExtension = 'pdf',
    this.fileSizeBytes = 0,
    this.ownerUserId,
    this.associatedUnitId,
    required this.createdAt,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      category: DocumentCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => DocumentCategory.general,
      ),
      fileUrl: json['fileUrl'] as String? ?? '',
      fileExtension: json['fileExtension'] as String? ?? 'pdf',
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      ownerUserId: json['ownerUserId'] as String?,
      associatedUnitId: json['associatedUnitId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'fileUrl': fileUrl,
      'fileExtension': fileExtension,
      'fileSizeBytes': fileSizeBytes,
      'ownerUserId': ownerUserId,
      'associatedUnitId': associatedUnitId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  DocumentItem copyWith({
    String? id,
    String? title,
    String? description,
    DocumentCategory? category,
    String? fileUrl,
    String? fileExtension,
    int? fileSizeBytes,
    String? ownerUserId,
    String? associatedUnitId,
    DateTime? createdAt,
  }) {
    return DocumentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      fileUrl: fileUrl ?? this.fileUrl,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      associatedUnitId: associatedUnitId ?? this.associatedUnitId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
