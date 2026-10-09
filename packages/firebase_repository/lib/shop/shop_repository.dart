import 'dart:async';
import 'package:models/models.dart';

abstract class ShopRepository {
  Stream<List<ShopModel>> streamShops(String organizationId);
  Future<List<ShopModel>> getAssignedShops(String employeeId);
  Future<void> addShop(ShopModel shop);
  Future<void> updateShop(ShopModel shop);
  Future<void> deleteShop(String shopId);
}

class MockShopRepository implements ShopRepository {
  final List<ShopModel> _shops = [
    ShopModel(
      id: 'shp_001',
      organizationId: 'org_acme_fmcg',
      name: 'Workout Gym & Fitness Center',
      code: 'GYM-KNP-01',
      address: 'Plot 14, Near Arya Nagar Crossing, Swaroop Nagar, Kanpur, Uttar Pradesh 208002',
      latitude: 26.4850,
      longitude: 80.3150,
      radius: 100.0,
      contactPerson: 'Amit Verma',
      phone: '+91 98390 11223',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now(),
    ),
    ShopModel(
      id: 'shp_002',
      organizationId: 'org_acme_fmcg',
      name: 'Z Square Mall Mega Store',
      code: 'SHP-KNP-02',
      address: '16/113 MG Road, Civil Lines, Kanpur, Uttar Pradesh 208001',
      latitude: 26.4725,
      longitude: 80.3522,
      radius: 120.0,
      contactPerson: 'Krishna Murari',
      phone: '+91 98390 22334',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    ShopModel(
      id: 'shp_003',
      organizationId: 'org_acme_fmcg',
      name: 'Kanpur Tilak Nagar (FF Sports)',
      code: 'SHP-KNP-03',
      address: 'Plot 45, Tilak Nagar, Kanpur, Uttar Pradesh 208002',
      latitude: 26.490745,
      longitude: 80.318524,
      radius: 80.0,
      contactPerson: 'Deepak Ahuja',
      phone: '+91 98390 33445',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
    ),
    ShopModel(
      id: 'shp_004',
      organizationId: 'org_acme_fmcg',
      name: 'Workout Gym & Fitness Center',
      code: 'GYM-KNP-01',
      address: 'Plot 14, Near Arya Nagar Crossing, Swaroop Nagar, Kanpur, Uttar Pradesh 208002',
      latitude: 26.4832,
      longitude: 80.3184,
      radius: 120.0,
      contactPerson: 'Amit Verma',
      phone: '+91 98390 11223',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
    ),
    ShopModel(
      id: 'shp_005',
      organizationId: 'org_acme_fmcg',
      name: 'Gold\'s Gym Kanpur Central',
      code: 'GYM-KNP-02',
      address: 'The Mall, Civil Lines, Kanpur, Uttar Pradesh 208001',
      latitude: 26.4678,
      longitude: 80.3496,
      radius: 150.0,
      contactPerson: 'Vikram Singh',
      phone: '+91 98390 44556',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
    ),
    ShopModel(
      id: 'shp_006',
      organizationId: 'org_acme_fmcg',
      name: 'Anytime Fitness & Crossfit Kanpur',
      code: 'GYM-KNP-03',
      address: 'Deoki Palace Crossing, Kakadeo, Kanpur, Uttar Pradesh 208025',
      latitude: 26.4795,
      longitude: 80.2921,
      radius: 100.0,
      contactPerson: 'Suresh Yadav',
      phone: '+91 98390 77889',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
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

  @override
  Future<void> updateShop(ShopModel shop) async {
    final idx = _shops.indexWhere((s) => s.id == shop.id);
    if (idx != -1) {
      _shops[idx] = shop;
    }
    _controller.add(List.unmodifiable(_shops));
  }

  @override
  Future<void> deleteShop(String shopId) async {
    _shops.removeWhere((s) => s.id == shopId);
    _controller.add(List.unmodifiable(_shops));
  }
}
