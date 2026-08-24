import 'package:flutter/foundation.dart';
import '../utils/date_time_util.dart';

@immutable
class Project {
  final String id;
  final String developerId;
  final String code;
  final String name;
  final String nameAr;
  final String description;
  final String city;
  final String district;
  final int totalCompounds;
  final int totalUnits;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.developerId,
    required this.code,
    required this.name,
    this.nameAr = '',
    this.description = '',
    required this.city,
    required this.district,
    this.totalCompounds = 0,
    this.totalUnits = 0,
    this.status = 'ACTIVE',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String? ?? '',
      developerId: json['developerId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      description: json['description'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      totalCompounds: (json['totalCompounds'] as num?)?.toInt() ?? 0,
      totalUnits: (json['totalUnits'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: DateTimeUtil.parse(json['createdAt']),
      updatedAt: DateTimeUtil.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'developerId': developerId,
      'code': code,
      'name': name,
      'nameAr': nameAr,
      'description': description,
      'city': city,
      'district': district,
      'totalCompounds': totalCompounds,
      'totalUnits': totalUnits,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Project copyWith({
    String? id,
    String? developerId,
    String? code,
    String? name,
    String? nameAr,
    String? description,
    String? city,
    String? district,
    int? totalCompounds,
    int? totalUnits,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      developerId: developerId ?? this.developerId,
      code: code ?? this.code,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      description: description ?? this.description,
      city: city ?? this.city,
      district: district ?? this.district,
      totalCompounds: totalCompounds ?? this.totalCompounds,
      totalUnits: totalUnits ?? this.totalUnits,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
