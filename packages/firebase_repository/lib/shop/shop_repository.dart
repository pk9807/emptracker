import 'dart:async';
import 'package:models/models.dart';

abstract class ShopRepository {
  Stream<List<ShopModel>> streamShops(String organizationId);
  Future<List<ShopModel>> getAssignedShops(String employeeId);
  Future<void> addShop(ShopModel shop);
}

class MockShopRepository implements ShopRepository {
  final List<ShopModel> _shops = [
    ShopModel(
      id: 'shp_001',
      organizationId: 'org_acme_fmcg',
      name: 'Shree Ganesh Supermart',
      code: 'SHP-CP-01',
      address: 'Block C, Connaught Place, New Delhi',
      latitude: 28.6328,
      longitude: 77.2197,
      radius: 100.0,
      contactPerson: 'Ramesh Gupta',
      phone: '+91 98111 00011',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now(),
    ),
    ShopModel(
      id: 'shp_002',
      organizationId: 'org_acme_fmcg',
      name: 'Krishna Kirana & Provision',
      code: 'SHP-CP-02',
      address: 'Main Market, Karol Bagh, New Delhi',
      latitude: 28.6514,
      longitude: 77.1907,
      radius: 80.0,
      contactPerson: 'Krishna Murari',
      phone: '+91 98222 00022',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    ShopModel(
      id: 'shp_003',
      organizationId: 'org_acme_fmcg',
      name: 'Modern Bazaar Mega Store',
      code: 'SHP-DEL-03',
      address: 'Defence Colony Market, New Delhi',
      latitude: 28.5733,
      longitude: 77.2343,
      radius: 150.0,
      contactPerson: 'Deepak Ahuja',
      phone: '+91 98333 00033',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
    ),
  ];

  final StreamController<List<ShopModel>> _controller =
      StreamController<List<ShopModel>>.broadcast();

  @override
  Stream<List<ShopModel>> streamShops(String organizationId) {
    Timer.run(() => _controller.add(List.unmodifiable(_shops)));
    return _controller.stream;
  }

  @override
  Future<List<ShopModel>> getAssignedShops(String employeeId) async {
    return List.unmodifiable(_shops);
  }

  @override
  Future<void> addShop(ShopModel shop) async {
    _shops.add(shop);
    _controller.add(List.unmodifiable(_shops));
  }
}
