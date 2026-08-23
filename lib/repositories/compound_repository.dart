import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/compound_model.dart';
import '../models/unit_model.dart';
import '../models/property_model.dart';
import '../services/live_price_state.dart';

class CompoundRepository {
  static const Duration _simulatedDelay = Duration(milliseconds: 800);

  Future<List<CompoundModel>> fetchCompounds() async {
    await Future.delayed(_simulatedDelay);
    return _dummyCompounds;
  }

  Future<CompoundModel> fetchCompoundById(String id) async {
    await Future.delayed(_simulatedDelay);
    return _dummyCompounds.firstWhere((c) => c.id == id);
  }

  Future<List<UnitModel>> fetchUnitsForCompound(String compoundId) async {
    await Future.delayed(_simulatedDelay);
    
    // Start with the standard mock units for this compound
    final list = _dummyUnits.where((u) => u.parentCompoundId == compoundId).toList();
    
    // Merge with live price state updates!
    final livePrices = LivePriceState.instance.currentPrices;
    if (livePrices.isNotEmpty) {
      final updatedList = list.map((u) {
        try {
          final tick = livePrices.firstWhere((t) => t.unitNumber == u.unitNumber);
          return u.copyWith(
            priceEGP: tick.priceEGP,
            pricePerSqFt: tick.pricePerSqFt,
          );
        } catch (_) {
          return u;
        }
      }).toList();

      // Dynamically add new units from live prices that aren't in dummy list!
      final liveUnitsForCompound = livePrices.where((t) => t.compoundId == compoundId);
      final existingNumbers = updatedList.map((u) => u.unitNumber).toSet();
      
      for (final tick in liveUnitsForCompound) {
        if (!existingNumbers.contains(tick.unitNumber)) {
          updatedList.add(UnitModel(
            unitNumber: tick.unitNumber,
            configuration: tick.assetDetail,
            areaSqFt: tick.pricePerSqFt > 0 ? (tick.priceEGP / tick.pricePerSqFt) : 1000.0,
            priceEGP: tick.priceEGP,
            isVacant: true,
            assetClass: 'Residential Suite',
            furnishingStatus: 'Standard Finishing',
            pricePerSqFt: tick.pricePerSqFt,
            parkingSpaces: 1,
            constructionPhase: 'Under Construction',
            parentCompoundId: compoundId,
            paymentMilestones: const [
              PaymentMilestone(title: 'Booking EOI Fee', percentageDue: 10, isPaid: false),
              PaymentMilestone(title: 'Contract Handover', percentageDue: 90, isPaid: false),
            ],
            floorTier: 'Ground Floor',
            areaSquareMeters: tick.pricePerSqFt > 0 ? (tick.priceEGP / tick.pricePerSqFt) / 10.764 : 100.0,
          ));
        }
      }
      return updatedList;
    }
    
    return list;
  }

  Future<List<Lead>> fetchLeads() async {
    await Future.delayed(_simulatedDelay);
    return _dummyLeads;
  }

  Future<List<BookingTransaction>> fetchTransactions() async {
    await Future.delayed(_simulatedDelay);
    return _dummyTransactions;
  }

  Future<List<Map<String, dynamic>>> fetchFractionalBlocks() async {
    await Future.delayed(_simulatedDelay);
    return _dummyFractionalBlocks;
  }

  static UnitModel? findUnitByNumber(String unitNumber) {
    try {
      return _dummyUnits.firstWhere((u) => u.unitNumber == unitNumber);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, String>>> fetchRegionalAverages() async {
    await Future.delayed(_simulatedDelay);
    return _dummyRegionalAverages;
  }

  static final List<Map<String, dynamic>> _localSubmittedEOIs = [];

  Uri get _submitUri {
    const String prodEndpoint = 'https://new-build-egypt.com/api/v1/eoi/submit';
    if (kIsWeb) {
      final baseUri = Uri.parse(Uri.base.toString());
      if (baseUri.host == 'localhost' || baseUri.host == '127.0.0.1') {
        return Uri.parse('http://localhost:8000/api/v1/eoi/submit');
      } else {
        return Uri(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.port,
          path: '/api/v1/eoi/submit',
        );
      }
    } else {
      if (kDebugMode) {
        return Uri.parse('http://localhost:8000/api/v1/eoi/submit');
      }
      return Uri.parse(prodEndpoint);
    }
  }

  Future<void> submitEOI({
    required String clientName,
    required String clientEmail,
    required String clientPhone,
    required String amount,
    required String compoundId,
    required String compoundTitle,
    required String unitType,
    String paymentMethod = 'Not Specified',
  }) async {
    final docId = FirebaseFirestore.instance.collection('eois').doc().id;
    final data = {
      'id': docId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'amount': amount,
      'compoundId': compoundId,
      'compoundTitle': compoundTitle,
      'unitType': unitType,
      'paymentMethod': paymentMethod,
      'timestamp': FieldValue.serverTimestamp(),
      'date': DateTime.now().toIso8601String().split('T')[0],
    };

    _localSubmittedEOIs.add(data);

    // 1. Try to submit to Firebase Firestore
    try {
      await FirebaseFirestore.instance
          .collection('eois')
          .doc(docId)
          .set(data)
          .timeout(const Duration(seconds: 4));
      debugPrint("[CompoundRepository] EOI successfully submitted to Firestore.");
    } catch (e) {
      debugPrint("[CompoundRepository] EOI Firestore save failed/offline (saved to local cache): $e");
    }

    // 2. HTTP Submission to local backend / website server (if not localhost)
    if (_submitUri.host != 'localhost' && _submitUri.host != '127.0.0.1') {
      try {
        final double amtDouble = double.tryParse(amount) ?? 0.0;
        final payload = {
          'id': docId,
          'name': clientName,
          'email': clientEmail,
          'phone': clientPhone,
          'amount': amtDouble,
          'compound_id': compoundId,
          'compound_title': compoundTitle,
          'unit_type': unitType,
          'payment_method': paymentMethod,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        };

        final response = await http.post(
          _submitUri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint("[CompoundRepository] HTTP EOI submission successful: ${response.body}");
        } else {
          debugPrint("[CompoundRepository] HTTP EOI submission failed with code ${response.statusCode}: ${response.body}");
        }
      } catch (e) {
        debugPrint("[CompoundRepository] HTTP EOI submission error: $e");
      }
    }
  }

  Future<List<Map<String, String>>> fetchBrokerHistory() async {
    List<Map<String, dynamic>> firestoreEOIs = [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('eois')
          .get()
          .timeout(const Duration(seconds: 3));

      for (var doc in snapshot.docs) {
        firestoreEOIs.add(doc.data());
      }
    } catch (e) {
      debugPrint("[CompoundRepository] Error fetching EOIs from Firestore: $e");
    }

    final Set<String> processedIds = {};
    final List<Map<String, String>> mergedList = [];

    // 1. Add Firestore EOIs
    for (final item in firestoreEOIs) {
      final id = item['id'] ?? '';
      if (id.isNotEmpty) processedIds.add(id);

      final double amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
      final payoutStr = "+${_formatEGP(amt)} EGP";
      mergedList.add({
        'id': id,
        'date': item['date'] ?? '',
        'details': "${item['compoundTitle']} ${item['unitType']} EOI Secure",
        'payout': payoutStr,
        'amount': item['amount']?.toString() ?? '0',
      });
    }

    // 2. Add local memory EOIs
    for (final item in _localSubmittedEOIs) {
      final id = item['id'] ?? '';
      if (id.isNotEmpty && processedIds.contains(id)) continue;
      if (id.isNotEmpty) processedIds.add(id);

      final double amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
      final payoutStr = "+${_formatEGP(amt)} EGP";
      mergedList.add({
        'id': id,
        'date': item['date'] ?? '',
        'details': "${item['compoundTitle']} ${item['unitType']} EOI Secure",
        'payout': payoutStr,
        'amount': item['amount']?.toString() ?? '0',
      });
    }

    // 3. Add dummy base history
    for (final dummy in _dummyBrokerHistory) {
      final amtClean = dummy['payout']!.replaceAll(RegExp(r'[^0-9]'), '');
      mergedList.add({
        'id': 'dummy_${dummy['date']}_${dummy['details']}',
        'date': dummy['date']!,
        'details': dummy['details']!,
        'payout': dummy['payout']!,
        'amount': amtClean,
      });
    }

    mergedList.sort((a, b) => b['date']!.compareTo(a['date']!));
    return mergedList;
  }

  static String _formatEGP(double val) {
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return val.toInt().toString().replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  static const List<CompoundModel> _dummyCompounds = [
    CompoundModel(
      id: 'dev_1',
      title: 'Sky Hills (سكي هيلز)',
      location: 'New October City, Greater Cairo',
      category: 'Residential',
      description: 'Premium elevated architecture in New October City featuring floor-to-ceiling glass, high-altitude unit allocations, and panoramic skyline views.',
      basePriceEGP: 45000000,
      areaSqFt: 1800,
      completionPercentage: 45.0,
      heroImageUrl: 'images/skyhills/ski-hills-overview.jpg',
      cardImageUrl: 'images/skyhills/ski-hills.jpg',
      primaryView: 'New October City Skyline',
      galleryPhotos: [
        MediaAsset(title: 'Overview', url: 'images/skyhills/ski-hills-overview.jpg'),
        MediaAsset(title: 'Overview Mobile', url: 'images/skyhills/ski-hills-overview-mobile.webp'),
        MediaAsset(title: 'Sky Hills Main', url: 'images/skyhills/ski-hills.jpg'),
        MediaAsset(title: 'Sky Hills 44', url: 'images/skyhills/ski-hills-44.jpg'),
        MediaAsset(title: 'Pricing View', url: 'images/skyhills/ski-hills-pricing.jpg'),
        MediaAsset(title: 'Services View', url: 'images/skyhills/ski-hills-services.jpg'),
        MediaAsset(title: 'Units View', url: 'images/skyhills/ski-hills-units.jpg'),
      ],
      droneClips: [
        MediaAsset(title: 'Overview WebP', url: 'images/skyhills/ski-hills-overview.webp'),
        MediaAsset(title: 'Main WebP', url: 'images/skyhills/ski-hills.webp'),
        MediaAsset(title: 'Sky Hills 44 WebP', url: 'images/skyhills/ski-hills-44.webp'),
        MediaAsset(title: 'Pricing WebP', url: 'images/skyhills/ski-hills-pricing.webp'),
        MediaAsset(title: 'Services WebP', url: 'images/skyhills/ski-hills-services.webp'),
        MediaAsset(title: 'Units WebP', url: 'images/skyhills/ski-hills-units.webp'),
        MediaAsset(title: 'Mobile WebP', url: 'images/skyhills/ski-hills-mobile.webp'),
      ],
      walkthroughs: [
        WalkthroughAsset(title: 'Interior 3D', room: 'Penthouse A'),
        WalkthroughAsset(title: 'Terrace VR', room: 'Duplex Sky'),
        WalkthroughAsset(title: 'Lobby VR', room: 'Main Entrance'),
      ],
      brochures: [
        BrochureAsset(title: 'Full Masterplan', url: 'https://gateway.iliving.com.eg/docs/sky_hills_masterplan.pdf'),
        BrochureAsset(title: 'Price Catalog', url: 'https://gateway.iliving.com.eg/docs/sky_hills_prices.pdf'),
        BrochureAsset(title: 'Dior Brochure', url: 'https://gateway.iliving.com.eg/docs/sky_hills_dior.pdf'),
      ],
    ),
    CompoundModel(
      id: 'dev_2',
      title: 'Lamar Compound (لمار كمبوند)',
      location: 'Sheikh Zayed City, Giza',
      category: 'Luxury Villas',
      description: 'Luxury green family community in Sheikh Zayed City featuring advanced smart gate operations, intensive landscaped gardens, and premium villa configurations.',
      basePriceEGP: 15000000,
      areaSqFt: 3200,
      completionPercentage: 72.0,
      heroImageUrl: 'images/lamar/lamar-1.jpg',
      cardImageUrl: 'images/lamar/lamar-2.jpg',
      primaryView: 'Landscaped Green Compound',
      galleryPhotos: [
        MediaAsset(title: 'Villa Exterior 1', url: 'images/lamar/lamar-1.jpg'),
        MediaAsset(title: 'Villa Exterior 2', url: 'images/lamar/lamar-2.jpg'),
        MediaAsset(title: 'Villa Exterior 3', url: 'images/lamar/lamar-3.jpg'),
        MediaAsset(title: 'Villa Exterior 4', url: 'images/lamar/lamar-4.jpg'),
        MediaAsset(title: 'Compound Garden', url: 'images/lamar/lamarrrr.jpg'),
      ],
      droneClips: [
        MediaAsset(title: 'Park Flythrough', url: 'images/lamar/lamar-1.jpg'),
        MediaAsset(title: 'Zayed Gate Drone', url: 'images/lamar/lamar-3.jpg'),
        MediaAsset(title: 'Villa Overlook', url: 'images/lamar/lamarrrr.jpg'),
      ],
      walkthroughs: [
        WalkthroughAsset(title: 'Family Villa 3D', room: 'Main Salon'),
        WalkthroughAsset(title: 'Garden VR', room: 'Backyard Oasis'),
        WalkthroughAsset(title: 'Master Suite 3D', room: 'Private Wing'),
      ],
      brochures: [
        BrochureAsset(title: 'Community Guide', url: 'https://gateway.iliving.com.eg/docs/lamar_community.pdf'),
        BrochureAsset(title: 'Villa Layouts', url: 'https://gateway.iliving.com.eg/docs/lamar_layouts.pdf'),
        BrochureAsset(title: 'Escrow Document', url: 'https://gateway.iliving.com.eg/docs/lamar_escrow.pdf'),
      ],
    ),
    CompoundModel(
      id: 'dev_3',
      title: 'Zayed Lagoons (زايد لاجونز)',
      location: 'West Cairo, Waterfront District',
      category: 'Luxury Villas',
      description: 'Elite waterfront villa configurations in West Cairo with exclusive marina access, private dock facilities, and unobstructed lagoon views.',
      basePriceEGP: 29000000,
      areaSqFt: 4800,
      completionPercentage: 35.0,
      heroImageUrl: 'images/zayed_lagoons/zayed-lahogons1.jpg',
      cardImageUrl: 'images/zayed_lagoons/zayed-lagons2.jpeg',
      primaryView: 'West Cairo Marina Lagoon',
      galleryPhotos: [
        MediaAsset(title: 'Lagoon Exterior 1', url: 'images/zayed_lagoons/zayed-lahogons1.jpg'),
        MediaAsset(title: 'Lagoon Exterior 2', url: 'images/zayed_lagoons/zayed-lagons2.jpeg'),
        MediaAsset(title: 'Lagoon Exterior 3', url: 'images/zayed_lagoons/zayed-lagons3.jpg'),
        MediaAsset(title: 'Villafront View', url: 'images/zayed_lagoons/zayed-3.jpg'),
      ],
      droneClips: [
        MediaAsset(title: 'Marina Drone', url: 'images/zayed_lagoons/zayed-lagons2.jpeg'),
        MediaAsset(title: 'Lagoon Sweep', url: 'images/zayed_lagoons/zayed-lahogons1.jpg'),
        MediaAsset(title: 'Yacht Dock Cam', url: 'images/zayed_lagoons/zayed-3.jpg'),
      ],
      walkthroughs: [
        WalkthroughAsset(title: 'Dock VR', room: 'Yacht Slip'),
        WalkthroughAsset(title: 'Waterfront 3D', room: 'Villa Lounge'),
        WalkthroughAsset(title: 'Marina Deck VR', room: 'Sunset Promenade'),
      ],
      brochures: [
        BrochureAsset(title: 'Waterfront Plans', url: 'https://gateway.iliving.com.eg/docs/zayed_lagoons_waterfront.pdf'),
        BrochureAsset(title: 'Marina Catalog', url: 'https://gateway.iliving.com.eg/docs/zayed_lagoons_marina.pdf'),
        BrochureAsset(title: 'Booking Schedule', url: 'https://gateway.iliving.com.eg/docs/zayed_lagoons_booking.pdf'),
      ],
    ),
  ];

  static final List<UnitModel> _dummyUnits = [
    const UnitModel(
      unitNumber: 'B01B202',
      configuration: '3 BR Garden Villa',
      areaSqFt: 1615.0,
      priceEGP: 3850000.0,
      isVacant: false,
      assetClass: 'Luxury Ground Villa',
      furnishingStatus: 'Fully Furnished',
      pricePerSqFt: 3850000.0 / 1615.0,
      parkingSpaces: 2,
      constructionPhase: 'Structure Complete',
      parentCompoundId: 'dev_1',
      paymentMilestones: [
        PaymentMilestone(title: 'Milestone 1: EOI Booking Fee', percentageDue: 10, isPaid: true),
        PaymentMilestone(title: 'Milestone 2: Within 30 days of SPA', percentageDue: 20, isPaid: false),
        PaymentMilestone(title: 'Milestone 3: Concrete Slab Casting', percentageDue: 30, isPaid: false),
        PaymentMilestone(title: 'Milestone 4: Superstructure Handover', percentageDue: 40, isPaid: false),
      ],
    ),
    const UnitModel(
      unitNumber: 'A103B202',
      configuration: '3 BR Luxury Suite',
      areaSqFt: 1937.0,
      priceEGP: 3725000.0,
      isVacant: false,
      assetClass: 'Premium Residential',
      furnishingStatus: 'Bespoke Premium Furnished',
      pricePerSqFt: 3725000.0 / 1937.0,
      parkingSpaces: 2,
      constructionPhase: 'Interior Fitting Out',
      parentCompoundId: 'dev_1',
      paymentMilestones: [
        PaymentMilestone(title: 'Milestone 1: EOI Booking Fee', percentageDue: 10, isPaid: true),
        PaymentMilestone(title: 'Milestone 2: Within 30 days of SPA', percentageDue: 20, isPaid: false),
        PaymentMilestone(title: 'Milestone 3: Concrete Slab Casting', percentageDue: 30, isPaid: false),
        PaymentMilestone(title: 'Milestone 4: Superstructure Handover', percentageDue: 40, isPaid: false),
      ],
    ),
    const UnitModel(
      unitNumber: 'B101B202',
      configuration: '3 BR Luxury Suite',
      areaSqFt: 1883.0,
      priceEGP: 3725000.0,
      isVacant: false,
      assetClass: 'Premium Residential',
      furnishingStatus: 'Bespoke Premium Furnished',
      pricePerSqFt: 3725000.0 / 1883.0,
      parkingSpaces: 2,
      constructionPhase: 'Interior Fitting Out',
      parentCompoundId: 'dev_1',
      paymentMilestones: [
        PaymentMilestone(title: 'Milestone 1: EOI Booking Fee', percentageDue: 10, isPaid: true),
        PaymentMilestone(title: 'Milestone 2: Within 30 days of SPA', percentageDue: 20, isPaid: false),
        PaymentMilestone(title: 'Milestone 3: Concrete Slab Casting', percentageDue: 30, isPaid: false),
        PaymentMilestone(title: 'Milestone 4: Superstructure Handover', percentageDue: 40, isPaid: false),
      ],
    ),
    const UnitModel(
      unitNumber: 'A01B202',
      configuration: '2 BR Garden Apartment',
      areaSqFt: 1291.0,
      priceEGP: 2700000.0,
      isVacant: false,
      assetClass: 'Luxury Ground Suite',
      furnishingStatus: 'Fully Furnished',
      pricePerSqFt: 2700000.0 / 1291.0,
      parkingSpaces: 1,
      constructionPhase: 'Structure Complete',
      parentCompoundId: 'dev_1',
      paymentMilestones: [
        PaymentMilestone(title: 'Milestone 1: EOI Booking Fee', percentageDue: 10, isPaid: true),
        PaymentMilestone(title: 'Milestone 2: Within 30 days of SPA', percentageDue: 20, isPaid: false),
        PaymentMilestone(title: 'Milestone 3: Concrete Slab Casting', percentageDue: 30, isPaid: false),
        PaymentMilestone(title: 'Milestone 4: Superstructure Handover', percentageDue: 40, isPaid: false),
      ],
    ),
    const UnitModel(
      unitNumber: 'B401B202',
      configuration: '4 BR Sky Penthouse',
      areaSqFt: 2690.0,
      priceEGP: 1750000.0,
      isVacant: false,
      assetClass: 'Signature Penthouse',
      furnishingStatus: 'Signature Bespoke VVIP',
      pricePerSqFt: 1750000.0 / 2690.0,
      parkingSpaces: 3,
      constructionPhase: 'Final Polishing Phase',
      parentCompoundId: 'dev_1',
      paymentMilestones: [
        PaymentMilestone(title: 'Milestone 1: EOI Booking Fee', percentageDue: 10, isPaid: true),
        PaymentMilestone(title: 'Milestone 2: Within 30 days of SPA', percentageDue: 20, isPaid: false),
        PaymentMilestone(title: 'Milestone 3: Concrete Slab Casting', percentageDue: 30, isPaid: false),
        PaymentMilestone(title: 'Milestone 4: Superstructure Handover', percentageDue: 40, isPaid: false),
      ],
    ),
    const UnitModel(
      unitNumber: 'A301B202',
      configuration: '3 BR Sky Suite',
      areaSqFt: 2260.0,
      priceEGP: 2485000.0,
      isVacant: false,
      assetClass: 'Premium High-Rise Suite',
      furnishingStatus: 'Bespoke Premium Furnished',
      pricePerSqFt: 2485000.0 / 2260.0,
      parkingSpaces: 2,
      constructionPhase: 'Interior Fitting Out',
      parentCompoundId: 'dev_1',
      paymentMilestones: [
        PaymentMilestone(title: 'Milestone 1: EOI Booking Fee', percentageDue: 10, isPaid: true),
        PaymentMilestone(title: 'Milestone 2: Within 30 days of SPA', percentageDue: 20, isPaid: false),
        PaymentMilestone(title: 'Milestone 3: Concrete Slab Casting', percentageDue: 30, isPaid: false),
        PaymentMilestone(title: 'Milestone 4: Superstructure Handover', percentageDue: 40, isPaid: false),
      ],
    ),
    const UnitModel(
      unitNumber: 'B302B202',
      configuration: '3 BR Sky Suite',
      areaSqFt: 2098.0,
      priceEGP: 2620000.0,
      isVacant: false,
      assetClass: 'Premium High-Rise Suite',
      furnishingStatus: 'Bespoke Premium Furnished',
      pricePerSqFt: 2620000.0 / 2098.0,
      parkingSpaces: 2,
      constructionPhase: 'Final Polishing Phase',
      parentCompoundId: 'dev_1',
      paymentMilestones: [
        PaymentMilestone(title: 'Milestone 1: EOI Booking Fee', percentageDue: 10, isPaid: true),
        PaymentMilestone(title: 'Milestone 2: Within 30 days of SPA', percentageDue: 20, isPaid: false),
        PaymentMilestone(title: 'Milestone 3: Concrete Slab Casting', percentageDue: 30, isPaid: false),
        PaymentMilestone(title: 'Milestone 4: Superstructure Handover', percentageDue: 40, isPaid: false),
      ],
    ),
    const UnitModel(
      unitNumber: 'B202B202',
      configuration: '3 BR Luxury Suite',
      areaSqFt: 2045.0,
      priceEGP: 2620000.0,
      isVacant: false,
      assetClass: 'Premium Residential',
      furnishingStatus: 'Bespoke Premium Furnished',
      pricePerSqFt: 2620000.0 / 2045.0,
      parkingSpaces: 2,
      constructionPhase: 'Interior Fitting Out',
      parentCompoundId: 'dev_1',
      paymentMilestones: [
        PaymentMilestone(title: 'Milestone 1: EOI Booking Fee', percentageDue: 10, isPaid: true),
        PaymentMilestone(title: 'Milestone 2: Within 30 days of SPA', percentageDue: 20, isPaid: false),
        PaymentMilestone(title: 'Milestone 3: Concrete Slab Casting', percentageDue: 30, isPaid: false),
        PaymentMilestone(title: 'Milestone 4: Superstructure Handover', percentageDue: 40, isPaid: false),
      ],
    ),
    const UnitModel(
      unitNumber: 'A203B202',
      configuration: '3 BR Luxury Suite',
      areaSqFt: 2368.0,
      priceEGP: 3025000.0,
      isVacant: false,
      assetClass: 'Premium Residential',
      furnishingStatus: 'Bespoke Premium Furnished',
      pricePerSqFt: 3025000.0 / 2368.0,
      parkingSpaces: 2,
      constructionPhase: 'Interior Fitting Out',
      parentCompoundId: 'dev_1',
      paymentMilestones: [
        PaymentMilestone(title: 'Milestone 1: EOI Booking Fee', percentageDue: 10, isPaid: true),
        PaymentMilestone(title: 'Milestone 2: Within 30 days of SPA', percentageDue: 20, isPaid: false),
        PaymentMilestone(title: 'Milestone 3: Concrete Slab Casting', percentageDue: 30, isPaid: false),
        PaymentMilestone(title: 'Milestone 4: Superstructure Handover', percentageDue: 40, isPaid: false),
      ],
    ),
    const UnitModel(
      unitNumber: 'B201B202',
      configuration: '3 BR Luxury Suite',
      areaSqFt: 2152.0,
      priceEGP: 2875000.0,
      isVacant: false,
      assetClass: 'Premium Residential',
      furnishingStatus: 'Bespoke Premium Furnished',
      pricePerSqFt: 2875000.0 / 2152.0,
      parkingSpaces: 2,
      constructionPhase: 'Interior Fitting Out',
      parentCompoundId: 'dev_1',
      paymentMilestones: [
        PaymentMilestone(title: 'Milestone 1: EOI Booking Fee', percentageDue: 10, isPaid: true),
        PaymentMilestone(title: 'Milestone 2: Within 30 days of SPA', percentageDue: 20, isPaid: false),
        PaymentMilestone(title: 'Milestone 3: Concrete Slab Casting', percentageDue: 30, isPaid: false),
        PaymentMilestone(title: 'Milestone 4: Superstructure Handover', percentageDue: 40, isPaid: false),
      ],
    ),
    const UnitModel(
      unitNumber: 'LM/12/1204',
      configuration: '2 BR + Maid',
      areaSqFt: 3200.0,
      priceEGP: 15000000.0,
      isVacant: true,
      assetClass: 'Luxury Villas',
      furnishingStatus: 'Fully Furnished',
      pricePerSqFt: 15000000.0 / 3200.0,
      parkingSpaces: 2,
      constructionPhase: 'Structure Complete',
      parentCompoundId: 'dev_2',
      paymentMilestones: [
        PaymentMilestone(title: 'Milestone 1: EOI Booking Fee', percentageDue: 10, isPaid: true),
        PaymentMilestone(title: 'Milestone 2: Within 30 days of SPA', percentageDue: 20, isPaid: false),
        PaymentMilestone(title: 'Milestone 3: Concrete Slab Casting', percentageDue: 30, isPaid: false),
        PaymentMilestone(title: 'Milestone 4: Superstructure Handover', percentageDue: 40, isPaid: false),
      ],
    ),
    const UnitModel(
      unitNumber: 'ZL/12/1204',
      configuration: '2 BR + Maid',
      areaSqFt: 4800.0,
      priceEGP: 29000000.0,
      isVacant: true,
      assetClass: 'Luxury Villas',
      furnishingStatus: 'Fully Furnished',
      pricePerSqFt: 29000000.0 / 4800.0,
      parkingSpaces: 2,
      constructionPhase: 'Structure Complete',
      parentCompoundId: 'dev_3',
      paymentMilestones: [
        PaymentMilestone(title: 'Milestone 1: EOI Booking Fee', percentageDue: 10, isPaid: true),
        PaymentMilestone(title: 'Milestone 2: Within 30 days of SPA', percentageDue: 20, isPaid: false),
        PaymentMilestone(title: 'Milestone 3: Concrete Slab Casting', percentageDue: 30, isPaid: false),
        PaymentMilestone(title: 'Milestone 4: Superstructure Handover', percentageDue: 40, isPaid: false),
      ],
    ),
  ];

  static final List<Lead> _dummyLeads = [
    Lead(
      id: 'lead_1',
      clientName: 'Lord Harrington',
      email: 'harrington@royal.uk',
      phone: '+44 7700 900077',
      status: LeadStatus.meetingScheduled,
      registeredAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Lead(
      id: 'lead_2',
      clientName: 'Princess Yasmin',
      email: 'yasmin@saudicrown.sa',
      phone: '+966 50 123 4567',
      status: LeadStatus.proposalSent,
      registeredAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Lead(
      id: 'lead_3',
      clientName: 'Dr. Hiroshi Sato',
      email: 'sato@cybernetics.tokyo',
      phone: '+81 90 8888 7777',
      status: LeadStatus.newLead,
      registeredAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  static final List<BookingTransaction> _dummyTransactions = [
    BookingTransaction(
      transactionId: 'TX-99420-A',
      buyerName: 'Elizabeth Windsor Estate',
      unitId: 'ZL/08/801',
      isDownPaymentPaid: true,
      status: BookingStatus.spaExecuted,
      contractedPriceEGP: 29000000.0,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      relationshipManager: 'Alistair Sterling',
      buyerRegistryInfo: 'UK Royal Crown Real Estate Trust Ltd - Registry #8849',
      invoiceUrl: 'https://gateway.iliving.com.eg/escrow/invoice_ZL_08_801.pdf',
    ),
    BookingTransaction(
      transactionId: 'TX-99421-B',
      buyerName: 'Khalid Al-Mansoor',
      unitId: 'SH/12/1204',
      isDownPaymentPaid: true,
      status: BookingStatus.pendingApproval,
      contractedPriceEGP: 45000000.0,
      timestamp: DateTime.now().subtract(const Duration(hours: 12)),
      relationshipManager: 'Alistair Sterling',
      buyerRegistryInfo: 'Mansoor Holding Capital - Registry #1194',
      invoiceUrl: 'https://gateway.iliving.com.eg/escrow/invoice_SH_12_1204.pdf',
    ),
    BookingTransaction(
      transactionId: 'TX-99422-C',
      buyerName: 'Dmitri Volkov',
      unitId: 'LM/05/501',
      isDownPaymentPaid: false,
      status: BookingStatus.rejected,
      contractedPriceEGP: 15000000.0,
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      relationshipManager: 'Alistair Sterling',
      buyerRegistryInfo: 'Volkov Maritime Logistics Group',
      invoiceUrl: 'https://gateway.iliving.com.eg/escrow/invoice_LM_05_501.pdf',
    ),
  ];

  static final List<Map<String, dynamic>> _dummyFractionalBlocks = [
    {
      'title': 'LAGOONS PROMENADE F1',
      'location': 'Sheikh Zayed',
      'roi': '9.2%',
      'shareEGP': '5,000',
      'percentage': 0.72,
      'image': 'images/zayed_lagoons/zayed-lahogons1.jpg',
    },
    {
      'title': 'SKY HILLS MICRO H1',
      'location': 'West Cairo',
      'roi': '9.5%',
      'shareEGP': '10,000',
      'percentage': 0.91,
      'image': 'images/skyhills/ski-hills.jpg',
    },
    {
      'title': 'LAMAR GARDEN G5',
      'location': 'New October',
      'roi': '8.8%',
      'shareEGP': '2,500',
      'percentage': 0.34,
      'image': 'images/lamar/lamar-2.jpg',
    },
    {
      'title': 'LAGOONS DOCK L4',
      'location': 'Sheikh Zayed',
      'roi': '9.0%',
      'shareEGP': '5,000',
      'percentage': 0.58,
      'image': 'images/zayed_lagoons/zayed-3.jpg',
    },
    {
      'title': 'SKY HILLS PENTHOUSE S8',
      'location': 'West Cairo',
      'roi': '9.8%',
      'shareEGP': '25,000',
      'percentage': 0.85,
      'image': 'images/skyhills/ski-hills-units.jpg',
    },
    {
      'title': 'LAMAR PLAZA VILLAS P2',
      'location': 'New October',
      'roi': '8.5%',
      'shareEGP': '50,000',
      'percentage': 0.49,
      'image': 'images/lamar/lamar-3.jpg',
    },
  ];

  static const List<Map<String, String>> _dummyRegionalAverages = [
    {'region': 'Sheikh Zayed (Sky Hills)', 'avg': '9.5% ROI'},
    {'region': 'New October (Lamar)', 'avg': '8.8% ROI'},
    {'region': 'Zayed Lagoons', 'avg': '9.2% ROI'},
    {'region': 'West Cairo Core', 'avg': '9.0% ROI'},
    {'region': 'New October North', 'avg': '8.4% ROI'},
    {'region': 'Zayed Lagoons Sector', 'avg': '9.6% ROI'},
  ];

  static const List<Map<String, String>> _dummyBrokerHistory = [
    {'date': '2026-05-20', 'details': 'Zayed Lagoons Villa EOI Secure', 'payout': '+3,800,000 EGP'},
    {'date': '2026-05-12', 'details': 'Sky Hills Penthouse Transacted', 'payout': '+2,250,000 EGP'},
    {'date': '2026-05-01', 'details': 'Lamar Compound Suite Transacted', 'payout': '+2,975,000 EGP'},
  ];
}
