import '../models/compound_model.dart';
import '../models/unit_model.dart';
import '../models/property_model.dart';

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
    return _dummyUnits.where((u) => u.parentCompoundId == compoundId).toList();
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

  Future<List<Map<String, String>>> fetchRegionalAverages() async {
    await Future.delayed(_simulatedDelay);
    return _dummyRegionalAverages;
  }

  Future<List<Map<String, String>>> fetchBrokerHistory() async {
    await Future.delayed(_simulatedDelay);
    return _dummyBrokerHistory;
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
      heroImageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80&w=1200',
      cardImageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80&w=600',
      primaryView: 'New October City Skyline',
      galleryPhotos: [
        MediaAsset(title: 'Sky Lobby', url: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&q=80&w=300'),
        MediaAsset(title: 'High Pool', url: 'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?auto=format&fit=crop&q=80&w=300'),
        MediaAsset(title: 'High Suite', url: 'https://images.unsplash.com/photo-1558036117-15d82a90b9b1?auto=format&fit=crop&q=80&w=300'),
      ],
      droneClips: [
        MediaAsset(title: 'Lobby Flight', url: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&q=80&w=300'),
        MediaAsset(title: 'Skyline View', url: 'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?auto=format&fit=crop&q=80&w=300'),
        MediaAsset(title: 'Phase 1 Drone', url: 'https://images.unsplash.com/photo-1558036117-15d82a90b9b1?auto=format&fit=crop&q=80&w=300'),
      ],
      walkthroughs: [
        WalkthroughAsset(title: 'Interior 3D', room: 'Penthouse A'),
        WalkthroughAsset(title: 'Terrace VR', room: 'Duplex Sky'),
        WalkthroughAsset(title: 'Lobby VR', room: 'Main Entrance'),
      ],
      brochures: [
        BrochureAsset(title: 'Full Masterplan', url: 'https://gateway.ihome.com.eg/docs/sky_hills_masterplan.pdf'),
        BrochureAsset(title: 'Price Catalog', url: 'https://gateway.ihome.com.eg/docs/sky_hills_prices.pdf'),
        BrochureAsset(title: 'Dior Brochure', url: 'https://gateway.ihome.com.eg/docs/sky_hills_dior.pdf'),
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
      heroImageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?auto=format&fit=crop&q=80&w=1200',
      cardImageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80&w=600',
      primaryView: 'Landscaped Green Compound',
      galleryPhotos: [
        MediaAsset(title: 'Villa Entrance', url: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80&w=300'),
        MediaAsset(title: 'Private Park', url: 'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?auto=format&fit=crop&q=80&w=300'),
        MediaAsset(title: 'Main Greenery', url: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80&w=300'),
      ],
      droneClips: [
        MediaAsset(title: 'Park Flythrough', url: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80&w=300'),
        MediaAsset(title: 'Zayed Gate Drone', url: 'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?auto=format&fit=crop&q=80&w=300'),
        MediaAsset(title: 'Villa Overlook', url: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80&w=300'),
      ],
      walkthroughs: [
        WalkthroughAsset(title: 'Family Villa 3D', room: 'Main Salon'),
        WalkthroughAsset(title: 'Garden VR', room: 'Backyard Oasis'),
        WalkthroughAsset(title: 'Master Suite 3D', room: 'Private Wing'),
      ],
      brochures: [
        BrochureAsset(title: 'Community Guide', url: 'https://gateway.ihome.com.eg/docs/lamar_community.pdf'),
        BrochureAsset(title: 'Villa Layouts', url: 'https://gateway.ihome.com.eg/docs/lamar_layouts.pdf'),
        BrochureAsset(title: 'Escrow Document', url: 'https://gateway.ihome.com.eg/docs/lamar_escrow.pdf'),
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
      heroImageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&q=80&w=1200',
      cardImageUrl: 'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&q=80&w=600',
      primaryView: 'West Cairo Marina Lagoon',
      galleryPhotos: [
        MediaAsset(title: 'Lagoon Front', url: 'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&q=80&w=300'),
        MediaAsset(title: 'Private Dock', url: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&q=80&w=300'),
        MediaAsset(title: 'West Marina', url: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80&w=300'),
      ],
      droneClips: [
        MediaAsset(title: 'Marina Drone', url: 'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&q=80&w=300'),
        MediaAsset(title: 'Lagoon Sweep', url: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&q=80&w=300'),
        MediaAsset(title: 'Yacht Dock Cam', url: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80&w=300'),
      ],
      walkthroughs: [
        WalkthroughAsset(title: 'Dock VR', room: 'Yacht Slip'),
        WalkthroughAsset(title: 'Waterfront 3D', room: 'Villa Lounge'),
        WalkthroughAsset(title: 'Marina Deck VR', room: 'Sunset Promenade'),
      ],
      brochures: [
        BrochureAsset(title: 'Waterfront Plans', url: 'https://gateway.ihome.com.eg/docs/zayed_lagoons_waterfront.pdf'),
        BrochureAsset(title: 'Marina Catalog', url: 'https://gateway.ihome.com.eg/docs/zayed_lagoons_marina.pdf'),
        BrochureAsset(title: 'Booking Schedule', url: 'https://gateway.ihome.com.eg/docs/zayed_lagoons_booking.pdf'),
      ],
    ),
  ];

  static final List<UnitModel> _dummyUnits = [
    UnitModel(
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
    UnitModel(
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
    UnitModel(
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
    UnitModel(
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
    UnitModel(
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
    UnitModel(
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
    UnitModel(
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
    UnitModel(
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
    UnitModel(
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
    UnitModel(
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
    UnitModel(
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
    UnitModel(
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
      invoiceUrl: 'https://gateway.ihome.com.eg/escrow/invoice_ZL_08_801.pdf',
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
      invoiceUrl: 'https://gateway.ihome.com.eg/escrow/invoice_SH_12_1204.pdf',
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
      invoiceUrl: 'https://gateway.ihome.com.eg/escrow/invoice_LM_05_501.pdf',
    ),
  ];

  static final List<Map<String, dynamic>> _dummyFractionalBlocks = [
    {
      'title': 'LAGOONS PROMENADE F1',
      'location': 'Sheikh Zayed',
      'roi': '9.2%',
      'shareEGP': '5,000',
      'percentage': 0.72,
      'image': 'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&q=80&w=300',
    },
    {
      'title': 'SKY HILLS MICRO H1',
      'location': 'West Cairo',
      'roi': '9.5%',
      'shareEGP': '10,000',
      'percentage': 0.91,
      'image': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80&w=300',
    },
    {
      'title': 'LAMAR GARDEN G5',
      'location': 'New October',
      'roi': '8.8%',
      'shareEGP': '2,500',
      'percentage': 0.34,
      'image': 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80&w=300',
    },
    {
      'title': 'LAGOONS DOCK L4',
      'location': 'Sheikh Zayed',
      'roi': '9.0%',
      'shareEGP': '5,000',
      'percentage': 0.58,
      'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80&w=300',
    },
    {
      'title': 'SKY HILLS PENTHOUSE S8',
      'location': 'West Cairo',
      'roi': '9.8%',
      'shareEGP': '25,000',
      'percentage': 0.85,
      'image': 'https://images.unsplash.com/photo-1600566752355-35792bedcfea?auto=format&fit=crop&q=80&w=300',
    },
    {
      'title': 'LAMAR PLAZA VILLAS P2',
      'location': 'New October',
      'roi': '8.5%',
      'shareEGP': '50,000',
      'percentage': 0.49,
      'image': 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&q=80&w=300',
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
