import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chapters/catalog.dart';

enum PurchaseResult { purchased, canceled, unavailable, failed }

/// Tienda de la plataforma (Google Play Billing / Apple StoreKit).
///
/// Esta entrega no integra ninguna: [DisabledPurchaseGateway] es la única
/// implementación y no puede cobrar. Una implementación real debe llamarse
/// solo desde pantallas protegidas por el control de adultos.
abstract class PurchaseGateway {
  /// Hay una tienda configurada y se pueden iniciar compras.
  bool get available;

  /// Productos que la tienda reconoce como comprados (también restaura).
  Future<Set<String>> ownedProducts();

  Future<PurchaseResult> buy(String productId);
}

/// Sin tienda: no hay productos, precios ni cobros.
class DisabledPurchaseGateway implements PurchaseGateway {
  const DisabledPurchaseGateway();

  @override
  bool get available => false;

  @override
  Future<Set<String>> ownedProducts() async => const {};

  @override
  Future<PurchaseResult> buy(String productId) async =>
      PurchaseResult.unavailable;
}

/// Derechos de acceso a capítulos.
///
/// Un capítulo gratuito siempre está desbloqueado. Uno de pago lo está si se
/// posee su producto o un paquete que lo enumere. Los productos comprados se
/// guardan en el dispositivo para que el contenido siga abierto sin conexión.
class Entitlements extends ChangeNotifier {
  Entitlements._(this._catalog, this._gateway, this._store, this._owned);

  static const String _kOwned = 'ownedProducts';

  final Catalog _catalog;
  final PurchaseGateway _gateway;
  final SharedPreferences _store;
  Set<String> _owned;

  static Future<Entitlements> load({
    required Catalog catalog,
    required PurchaseGateway gateway,
  }) async {
    final store = await SharedPreferences.getInstance();
    return Entitlements._(
      catalog,
      gateway,
      store,
      (store.getStringList(_kOwned) ?? const []).toSet(),
    );
  }

  bool get storeAvailable => _gateway.available;

  bool isUnlocked(Chapter chapter) {
    final product = chapter.access.productId;
    if (product == null || _owned.contains(product)) return true;
    return _catalog.bundles.any(
      (b) => _owned.contains(b.productId) && b.chapterIds.contains(chapter.id),
    );
  }

  /// Paquetes que incluyen [chapter], con su lista cerrada de capítulos.
  List<ChapterBundle> bundlesFor(Chapter chapter) => [
    for (final b in _catalog.bundles)
      if (b.chapterIds.contains(chapter.id)) b,
  ];

  Future<void> _setOwned(Set<String> owned) async {
    if (setEquals(owned, _owned)) return;
    _owned = owned;
    await _store.setStringList(_kOwned, owned.toList()..sort());
    notifyListeners();
  }

  /// Compra [productId]. Solo desde el área protegida para adultos.
  Future<PurchaseResult> buy(String productId) async {
    if (!_gateway.available) return PurchaseResult.unavailable;
    final PurchaseResult result;
    try {
      result = await _gateway.buy(productId);
    } catch (_) {
      return PurchaseResult.failed;
    }
    if (result == PurchaseResult.purchased) {
      await _setOwned({..._owned, productId});
    }
    return result;
  }

  /// Sincroniza con la tienda. Si falla (p. ej. sin conexión) se conserva lo
  /// ya guardado: nunca se retira contenido por un error de red.
  Future<bool> restore() async {
    if (!_gateway.available) return false;
    try {
      await _setOwned({..._owned, ...await _gateway.ownedProducts()});
      return true;
    } catch (_) {
      return false;
    }
  }
}
