import 'package:flutter/foundation.dart';
import '../models/unit_price_tick.dart';

class LivePriceState {
  LivePriceState._internal();

  static final LivePriceState instance = LivePriceState._internal();

  final ValueNotifier<List<UnitPriceTick>> pricesNotifier =
      ValueNotifier<List<UnitPriceTick>>([]);

  List<UnitPriceTick> get currentPrices => pricesNotifier.value;

  void update(List<UnitPriceTick> ticks) {
    pricesNotifier.value = List.unmodifiable(ticks);
  }

  UnitPriceTick? tickForUnit(String unitNumber) {
    try {
      return currentPrices.firstWhere((t) => t.unitNumber == unitNumber);
    } catch (_) {
      return null;
    }
  }

  UnitPriceTick? tickForCompound(String compoundId) {
    try {
      return currentPrices.firstWhere((t) => t.compoundId == compoundId);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    pricesNotifier.dispose();
  }
}
