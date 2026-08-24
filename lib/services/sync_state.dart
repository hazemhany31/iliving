import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/auth_model.dart';
import '../models/unit_price_tick.dart';
import '../repositories/price_sync_repository.dart';
import 'auth_service.dart';

class SyncStateManager extends ChangeNotifier {
  StreamSubscription<List<UnitPriceTick>>? _priceSub;

  SyncStateManager() {
    AuthService.instance.stateNotifier.addListener(_onAuthStateChanged);
    PriceSyncRepository.instance.statusNotifier.addListener(_onSyncStatusChanged);
    _priceSub = PriceSyncRepository.instance.priceFeed.listen(_onPriceUpdate);
  }

  AuthState get authState => AuthService.instance.currentState;
  SyncStatus get syncStatus => PriceSyncRepository.instance.status;
  List<UnitPriceTick> get latestPrices => PriceSyncRepository.instance.lastSnapshot;

  Stream<List<UnitPriceTick>> get priceFeed => PriceSyncRepository.instance.priceFeed;

  Future<void> initialize() async {
    await AuthService.instance.initialize();
    if (AuthService.instance.currentState == AuthState.authenticated) {
      await PriceSyncRepository.instance.startSync();
    }
  }

  Future<bool> login(String email, String password) async {
    final success = await AuthService.instance.login(email, password);
    if (success) {
      await PriceSyncRepository.instance.startSync();
      notifyListeners();
    }
    return success;
  }

  Future<void> logout() async {
    PriceSyncRepository.instance.stopSync();
    await AuthService.instance.logout();
    notifyListeners();
  }

  Future<void> forceRefreshPrices() => PriceSyncRepository.instance.forceRefresh();

  UnitPriceTick? priceTickForUnit(String unitNumber) =>
      PriceSyncRepository.instance.priceTickForUnit(unitNumber);

  UnitPriceTick? priceTickForCompound(String compoundId) =>
      PriceSyncRepository.instance.priceTickForCompound(compoundId);

  void _onAuthStateChanged() {
    final state = AuthService.instance.currentState;
    if (state == AuthState.authenticated) {
      PriceSyncRepository.instance.startSync();
    } else if (state == AuthState.unauthenticated ||
        state == AuthState.sessionExpired) {
      PriceSyncRepository.instance.stopSync();
    }
    notifyListeners();
  }

  void _onSyncStatusChanged() {
    notifyListeners();
  }

  void _onPriceUpdate(List<UnitPriceTick> ticks) {
    notifyListeners();
  }

  @override
  void dispose() {
    _priceSub?.cancel();
    AuthService.instance.stateNotifier.removeListener(_onAuthStateChanged);
    PriceSyncRepository.instance.statusNotifier.removeListener(_onSyncStatusChanged);
    super.dispose();
  }
}

class SyncScope extends InheritedNotifier<SyncStateManager> {
  const SyncScope({
    super.key,
    required SyncStateManager manager,
    required super.child,
  }) : super(notifier: manager);

  static SyncStateManager of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SyncScope>();
    assert(scope != null, 'SyncScope not found in widget tree');
    return scope!.notifier!;
  }

  static SyncStateManager? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SyncScope>()?.notifier;
  }
}
