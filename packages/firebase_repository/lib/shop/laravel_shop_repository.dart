import 'dart:async';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'shop_repository.dart';

class LaravelShopRepository implements ShopRepository {
  final ApiClient _api = ApiClient();
  final StreamController<List<ShopModel>> _controller =
      StreamController<List<ShopModel>>.broadcast();

  LaravelShopRepository() {
    _fetchShops();
  }

  Future<void> _fetchShops() async {
    try {
      final res = await _api.get('/shops');
      if (res.isSuccess && res.data is List) {
        final list = (res.data as List).map((item) {
          final map = item as Map<String, dynamic>;
          return ShopModel(
            id: map['id'].toString(),
            organizationId: 'org_1',
            name: map['name'] as String? ?? 'Shop',
            code: map['qr_code'] as String? ?? 'SHP-${map['id']}',
            address: map['address'] as String? ?? '',
            latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
            radius: (map['geofence_radius_meters'] as num?)?.toDouble() ?? 100.0,
            contactPerson: map['owner_name'] as String?,
            phone: map['phone'] as String?,
            createdAt: map['created_at'] != null
                ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
                : DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();

        _controller.add(List.unmodifiable(list));
      }
    } catch (_) {}
  }

  @override
  Stream<List<ShopModel>> streamShops(String organizationId) {
    _fetchShops();
    return _controller.stream;
  }

  @override
  Future<List<ShopModel>> getAssignedShops(String employeeId) async {
    try {
      final res = await _api.get('/shops');
      if (res.isSuccess && res.data is List) {
        return (res.data as List).map((item) {
          final map = item as Map<String, dynamic>;
          return ShopModel(
            id: map['id'].toString(),
            organizationId: 'org_1',
            name: map['name'] as String? ?? 'Shop',
            code: map['qr_code'] as String? ?? 'SHP-${map['id']}',
            address: map['address'] as String? ?? '',
            latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
            radius: (map['geofence_radius_meters'] as num?)?.toDouble() ?? 100.0,
            contactPerson: map['owner_name'] as String?,
            phone: map['phone'] as String?,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> addShop(ShopModel shop) async {
    try {
      await _api.post('/shops', body: {
        'name': shop.name,
        'owner_name': shop.contactPerson,
        'phone': shop.phone,
        'address': shop.address,
        'latitude': shop.latitude,
        'longitude': shop.longitude,
        'geofence_radius_meters': shop.radius.toInt(),
        'qr_code': shop.code,
      });
      await _fetchShops();
    } catch (_) {}
  }

  @override
  Future<void> updateShop(ShopModel shop) async {
    try {
      await _api.put('/shops/${shop.id}', body: {
        'name': shop.name,
        'owner_name': shop.contactPerson,
        'phone': shop.phone,
        'address': shop.address,
        'latitude': shop.latitude,
        'longitude': shop.longitude,
        'geofence_radius_meters': shop.radius.toInt(),
      });
      await _fetchShops();
    } catch (_) {}
  }

  @override
  Future<void> deleteShop(String shopId) async {
    try {
      await _api.delete('/shops/$shopId');
      await _fetchShops();
    } catch (_) {}
  }
}
