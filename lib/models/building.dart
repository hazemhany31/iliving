import 'package:flutter/foundation.dart';
import '../utils/date_time_util.dart';

@immutable
class Building {
  final String id;
  final String compoundId;
  final String code;
  final String name;
  final String nameAr;
  final int totalFloors;
  final int totalUnits;
  final List<String> amenities;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Building({
    required this.id,
    required this.compoundId,
    required this.code,
    required this.name,
    this.nameAr = '',
    this.totalFloors = 1,
    this.totalUnits = 0,
    this.amenities = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'] as String? ?? '',
      compoundId: json['compoundId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      totalFloors: (json['totalFloors'] as num?)?.toInt() ?? 1,
      totalUnits: (json['totalUnits'] as num?)?.toInt() ?? 0,
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTimeUtil.parse(json['createdAt']),
      updatedAt: DateTimeUtil.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'compoundId': compoundId,
      'code': code,
      'name': name,
      'nameAr': nameAr,
      'totalFloors': totalFloors,
      'totalUnits': totalUnits,
      'amenities': amenities,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Building copyWith({
    String? id,
    String? compoundId,
    String? code,
    String? name,
    String? nameAr,
    int? totalFloors,
    int? totalUnits,
    List<String>? amenities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Building(
      id: id ?? this.id,
      compoundId: compoundId ?? this.compoundId,
      code: code ?? this.code,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      totalFloors: totalFloors ?? this.totalFloors,
      totalUnits: totalUnits ?? this.totalUnits,
      amenities: amenities ?? this.amenities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Building && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
