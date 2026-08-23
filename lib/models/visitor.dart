import 'package:flutter/foundation.dart';

@immutable
class Visitor {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String nationalIdOrPassport;
  final String? vehiclePlateNumber;
  final DateTime createdAt;

  const Visitor({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.nationalIdOrPassport = '',
    this.vehiclePlateNumber,
    required this.createdAt,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      nationalIdOrPassport: json['nationalIdOrPassport'] as String? ?? '',
      vehiclePlateNumber: json['vehiclePlateNumber'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'nationalIdOrPassport': nationalIdOrPassport,
      'vehiclePlateNumber': vehiclePlateNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Visitor copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? nationalIdOrPassport,
    String? vehiclePlateNumber,
    DateTime? createdAt,
  }) {
    return Visitor(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nationalIdOrPassport: nationalIdOrPassport ?? this.nationalIdOrPassport,
      vehiclePlateNumber: vehiclePlateNumber ?? this.vehiclePlateNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Visitor && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
