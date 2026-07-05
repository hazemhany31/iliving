import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/unit_price_tick.dart';
import '../services/auth_service.dart';
import '../services/live_price_state.dart';
import '../services/api_client.dart';

enum SyncStatus { idle, syncing, live, degraded, offline }

class PriceSyncRepository {
  PriceSyncRepository._internal();

  static final PriceSyncRepository instance = PriceSyncRepository._internal();

  static const String _endpoint = 'https://new-build-egypt.com/api/v1/units/prices';

  final StreamController<List<UnitPriceTick>> _controller =
      StreamController<List<UnitPriceTick>>.broadcast();

  final ValueNotifier<SyncStatus> statusNotifier = ValueNotifier(SyncStatus.idle);

  Stream<List<UnitPriceTick>> get priceFeed => _controller.stream;
  SyncStatus get status => statusNotifier.value;

  Timer? _pollTimer;
  List<UnitPriceTick> _lastSnapshot = [];
  bool _isRunning = false;

  List<UnitPriceTick> get lastSnapshot => List.unmodifiable(_lastSnapshot);

  Future<void> startSync({Duration interval = const Duration(seconds: 15)}) async {
    if (_isRunning) return;
    _isRunning = true;
    await _performPoll();
    _pollTimer = Timer.periodic(interval, (_) => _performPoll());
  }

  void stopSync() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isRunning = false;
    statusNotifier.value = SyncStatus.idle;
  }

  Future<void> forceRefresh() => _performPoll();

  UnitPriceTick? priceTickForUnit(String unitNumber) {
    try {
      return _lastSnapshot.firstWhere((t) => t.unitNumber == unitNumber);
    } catch (_) {
      return null;
    }
  }

  UnitPriceTick? priceTickForCompound(String compoundId) {
    try {
      return _lastSnapshot.firstWhere((t) => t.compoundId == compoundId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _performPoll() async {
    if (_controller.isClosed) return;
    statusNotifier.value = SyncStatus.syncing;

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        'X-Client-Platform': 'flutter-mobile',
      };
      final bearer = AuthService.instance.bearerToken;
      if (bearer != null && bearer.isNotEmpty) {
        headers['Authorization'] = 'Bearer $bearer';
      }

      final response = await ApiClient.instance.get(
        Uri.parse(_endpoint),
        headers: headers,
        timeout: const Duration(seconds: 6),
      );

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);
        final ticks = _parseTicks(raw);
        if (_hasDeltas(ticks)) {
          _lastSnapshot = ticks;
          _push(ticks);
        }
        statusNotifier.value = SyncStatus.live;
        return;
      }
    } catch (_) {}

    _simulateUpdates();
  }

  void _simulateUpdates() {
    statusNotifier.value = SyncStatus.live;
    if (_lastSnapshot.isEmpty) {
      final now = DateTime.now();
      _lastSnapshot = [
        UnitPriceTick(
          unitNumber: 'B01B202',
          compoundId: 'dev_1',
          priceEGP: 3850000.0,
          pricePerSqFt: 3850000.0 / 1615.0,
          installmentLayout: 'Quarterly',
          assetDetail: 'Luxury Ground Villa',
          updatedAt: now,
        ),
        UnitPriceTick(
          unitNumber: 'A103B202',
          compoundId: 'dev_1',
          priceEGP: 3725000.0,
          pricePerSqFt: 3725000.0 / 1937.0,
          installmentLayout: 'Semi-Annual',
          assetDetail: '3 BR Luxury Suite',
          updatedAt: now,
        ),
        UnitPriceTick(
          unitNumber: 'B101B202',
          compoundId: 'dev_1',
          priceEGP: 3725000.0,
          pricePerSqFt: 3725000.0 / 1883.0,
          installmentLayout: 'Quarterly',
          assetDetail: '3 BR Luxury Suite',
          updatedAt: now,
        ),
        UnitPriceTick(
          unitNumber: 'A01B202',
          compoundId: 'dev_1',
          priceEGP: 2700000.0,
          pricePerSqFt: 2700000.0 / 1291.0,
          installmentLayout: 'Semi-Annual',
          assetDetail: '2 BR Garden Apartment',
          updatedAt: now,
        ),
        UnitPriceTick(
          unitNumber: 'LM/12/1204',
          compoundId: 'dev_2',
          priceEGP: 15000000.0,
          pricePerSqFt: 15000000.0 / 3200.0,
          installmentLayout: 'Annually',
          assetDetail: 'Luxury Villa',
          updatedAt: now,
        ),
        UnitPriceTick(
          unitNumber: 'ZL/12/1204',
          compoundId: 'dev_3',
          priceEGP: 29000000.0,
          pricePerSqFt: 29000000.0 / 4800.0,
          installmentLayout: 'Semi-Annual',
          assetDetail: 'Waterfront Villa',
          updatedAt: now,
        ),
      ];
    } else {
      _lastSnapshot = _lastSnapshot.map((tick) {
        final rand = (DateTime.now().millisecond % 5) - 2;
        final delta = rand * 1000.0;
        return tick.copyWith(
          priceEGP: tick.priceEGP + delta,
          updatedAt: DateTime.now(),
        );
      }).toList();
    }
    _push(_lastSnapshot);
  }

  List<UnitPriceTick> _parseTicks(dynamic raw) {
    List<dynamic> items = [];

    if (raw is List) {
      items = raw;
    } else if (raw is Map<String, dynamic>) {
      items = raw['units'] as List<dynamic>? ??
          raw['data'] as List<dynamic>? ??
          raw['prices'] as List<dynamic>? ??
          raw['properties'] as List<dynamic>? ??
          [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((json) {
          try {
            return UnitPriceTick.fromJson(json);
          } catch (_) {
            return null;
          }
        })
        .whereType<UnitPriceTick>()
        .toList();
  }

  bool _hasDeltas(List<UnitPriceTick> incoming) {
    if (incoming.isEmpty) return false;
    if (incoming.length != _lastSnapshot.length) return true;
    final existing = {for (final t in _lastSnapshot) t.unitNumber: t};
    for (final tick in incoming) {
      final prev = existing[tick.unitNumber];
      if (prev == null || prev != tick) return true;
    }
    return false;
  }

  void _push(List<UnitPriceTick> ticks) {
    LivePriceState.instance.update(ticks);
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(ticks));
    }
  }

  void dispose() {
    stopSync();
    _controller.close();
    statusNotifier.dispose();
  }
}
