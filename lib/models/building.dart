import 'package:flutter/foundation.dart';

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
      totalFloors: json['totalFloors'] as int? ?? 1,
      totalUnits: json['totalUnits'] as int? ?? 0,
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
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
