class MediaAsset {
  final String title;
  final String url;

  const MediaAsset({
    required this.title,
    required this.url,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
    };
  }
}

class WalkthroughAsset {
  final String title;
  final String room;
  final String? url;

  const WalkthroughAsset({
    required this.title,
    required this.room,
    this.url,
  });

  factory WalkthroughAsset.fromJson(Map<String, dynamic> json) {
    return WalkthroughAsset(
      title: json['title'] as String? ?? '',
      room: json['room'] as String? ?? '',
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'room': room,
      'url': url,
    };
  }
}

class BrochureAsset {
  final String title;
  final String url;

  const BrochureAsset({
    required this.title,
    required this.url,
  });

  factory BrochureAsset.fromJson(Map<String, dynamic> json) {
    return BrochureAsset(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
    };
  }
}

class CompoundModel {
  final String id;
  final String title;
  final String location;
  final String category;
  final String description;
  final double basePriceEGP;
  final double areaSqFt;
  final double completionPercentage;
  final String heroImageUrl;
  final String cardImageUrl;
  final String primaryView;
  final String? droneVideoUrl;
  final String? walkthrough3DUrl;
  final List<MediaAsset> galleryPhotos;
  final List<MediaAsset> droneClips;
  final List<WalkthroughAsset> walkthroughs;
  final List<BrochureAsset> brochures;

  const CompoundModel({
    required this.id,
    required this.title,
    required this.location,
    required this.category,
    required this.description,
    required this.basePriceEGP,
    required this.areaSqFt,
    required this.completionPercentage,
    required this.heroImageUrl,
    required this.cardImageUrl,
    required this.primaryView,
    this.droneVideoUrl,
    this.walkthrough3DUrl,
    this.galleryPhotos = const [],
    this.droneClips = const [],
    this.walkthroughs = const [],
    this.brochures = const [],
  });

  factory CompoundModel.fromJson(Map<String, dynamic> json) {
    return CompoundModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      basePriceEGP: (json['basePriceEGP'] as num?)?.toDouble() ?? 0.0,
      areaSqFt: (json['areaSqFt'] as num?)?.toDouble() ?? 0.0,
      completionPercentage: (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      heroImageUrl: json['heroImageUrl'] as String? ?? '',
      cardImageUrl: json['cardImageUrl'] as String? ?? '',
      primaryView: json['primaryView'] as String? ?? '',
      droneVideoUrl: json['droneVideoUrl'] as String?,
      walkthrough3DUrl: json['walkthrough3DUrl'] as String?,
      galleryPhotos: (json['galleryPhotos'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => MediaAsset.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      droneClips: (json['droneClips'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => MediaAsset.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      walkthroughs: (json['walkthroughs'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => WalkthroughAsset.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      brochures: (json['brochures'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => BrochureAsset.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'category': category,
      'description': description,
      'basePriceEGP': basePriceEGP,
      'areaSqFt': areaSqFt,
      'completionPercentage': completionPercentage,
      'heroImageUrl': heroImageUrl,
      'cardImageUrl': cardImageUrl,
      'primaryView': primaryView,
      'droneVideoUrl': droneVideoUrl,
      'walkthrough3DUrl': walkthrough3DUrl,
      'galleryPhotos': galleryPhotos.map((e) => e.toJson()).toList(),
      'droneClips': droneClips.map((e) => e.toJson()).toList(),
      'walkthroughs': walkthroughs.map((e) => e.toJson()).toList(),
      'brochures': brochures.map((e) => e.toJson()).toList(),
    };
  }

  CompoundModel copyWith({
    String? id,
    String? title,
    String? location,
    String? category,
    String? description,
    double? basePriceEGP,
    double? areaSqFt,
    double? completionPercentage,
    String? heroImageUrl,
    String? cardImageUrl,
    String? primaryView,
    String? droneVideoUrl,
    String? walkthrough3DUrl,
    List<MediaAsset>? galleryPhotos,
    List<MediaAsset>? droneClips,
    List<WalkthroughAsset>? walkthroughs,
    List<BrochureAsset>? brochures,
  }) {
    return CompoundModel(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      category: category ?? this.category,
      description: description ?? this.description,
      basePriceEGP: basePriceEGP ?? this.basePriceEGP,
      areaSqFt: areaSqFt ?? this.areaSqFt,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      cardImageUrl: cardImageUrl ?? this.cardImageUrl,
      primaryView: primaryView ?? this.primaryView,
      droneVideoUrl: droneVideoUrl ?? this.droneVideoUrl,
      walkthrough3DUrl: walkthrough3DUrl ?? this.walkthrough3DUrl,
      galleryPhotos: galleryPhotos ?? this.galleryPhotos,
      droneClips: droneClips ?? this.droneClips,
      walkthroughs: walkthroughs ?? this.walkthroughs,
      brochures: brochures ?? this.brochures,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompoundModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
