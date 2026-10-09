<?php

namespace Database\Seeders;

use App\Models\Attendance;
use App\Models\LiveLocation;
use App\Models\LocationHistory;
use App\Models\Shop;
use App\Models\User;
use App\Models\Visit;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create Admin User
        $admin = User::updateOrCreate(
            ['email' => 'admin@fieldforce.com'],
            [
                'name' => 'FieldForce Master Admin',
                'password' => Hash::make('Admin@123456'),
                'role' => 'admin',
                'phone' => '+91 98765 43210',
                'employee_code' => 'ADM-001',
                'designation' => 'Regional Operations Manager',
                'department' => 'Operations & Logistics',
                'avatar' => 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                'is_active' => true,
            ]
        );

        // 2. Create Field Employees (Sales Representatives)
        $employeesData = [
            [
                'name' => 'Rahul Sharma',
                'email' => 'rahul@fieldforce.com',
                'password' => Hash::make('Emp@123456'),
                'phone' => '+91 98111 22334',
                'employee_code' => 'EMP-101',
                'designation' => 'Senior Field Executive',
                'department' => 'FMCG Sales',
                'avatar' => 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                'lat' => 26.4850,
                'lng' => 80.3150,
                'heading' => 45.0,
                'speed' => 24.5,
                'battery' => 88,
                'activity' => 'IN_VEHICLE',
            ],
            [
                'name' => 'Priya Patel',
                'email' => 'priya@fieldforce.com',
                'password' => Hash::make('Emp@123456'),
                'phone' => '+91 98222 33445',
                'employee_code' => 'EMP-102',
                'designation' => 'Retail Territory Officer',
                'department' => 'Retail Distribution',
                'avatar' => 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
                'lat' => 26.4725,
                'lng' => 80.3522,
                'heading' => 120.0,
                'speed' => 18.2,
                'battery' => 74,
                'activity' => 'ON_BICYCLE',
            ],
            [
                'name' => 'Amit Verma',
                'email' => 'amit@fieldforce.com',
                'password' => Hash::make('Emp@123456'),
                'phone' => '+91 98333 44556',
                'employee_code' => 'EMP-103',
                'designation' => 'Area Sales Executive',
                'department' => 'Key Accounts',
                'avatar' => 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
                'lat' => 26.4812,
                'lng' => 80.2928,
                'heading' => 210.0,
                'speed' => 32.0,
                'battery' => 92,
                'activity' => 'IN_VEHICLE',
            ],
            [
                'name' => 'Vikram Singh',
                'email' => 'vikram@fieldforce.com',
                'password' => Hash::make('Emp@123456'),
                'phone' => '+91 98444 55667',
                'employee_code' => 'EMP-104',
                'designation' => 'Medical Representative',
                'department' => 'Pharma Sales',
                'avatar' => 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
                'lat' => 26.4907,
                'lng' => 80.3185,
                'heading' => 315.0,
                'speed' => 4.5,
                'battery' => 65,
                'activity' => 'WALKING',
            ],
            [
                'name' => 'Ananya Sen',
                'email' => 'ananya@fieldforce.com',
                'password' => Hash::make('Emp@123456'),
                'phone' => '+91 98555 66778',
                'employee_code' => 'EMP-105',
                'designation' => 'Business Development Executive',
                'department' => 'Direct Marketing',
                'avatar' => 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
                'lat' => 26.4670,
                'lng' => 80.3500,
                'heading' => 90.0,
                'speed' => 0.0,
                'battery' => 95,
                'activity' => 'STILL',
            ],
        ];

        $createdEmployees = [];

        foreach ($employeesData as $data) {
            $user = User::updateOrCreate(
                ['email' => $data['email']],
                [
                    'name' => $data['name'],
                    'password' => $data['password'],
                    'role' => 'employee',
                    'phone' => $data['phone'],
                    'employee_code' => $data['employee_code'],
                    'designation' => $data['designation'],
                    'department' => $data['department'],
                    'avatar' => $data['avatar'],
                    'is_active' => true,
                ]
            );

            $createdEmployees[] = $user;

            // Seed Live Location (Ola / Uber radar representation)
            LiveLocation::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'latitude' => $data['lat'],
                    'longitude' => $data['lng'],
                    'accuracy' => 5.2,
                    'speed' => $data['speed'],
                    'heading' => $data['heading'],
                    'altitude' => 215.0,
                    'battery_level' => $data['battery'],
                    'is_mocked' => false,
                    'activity_type' => $data['activity'],
                    'is_online' => true,
                    'last_ping_at' => Carbon::now(),
                ]
            );

            // Seed Attendance for Today
            Attendance::updateOrCreate(
                [
                    'user_id' => $user->id,
                    'date' => Carbon::today()->toDateString(),
                ],
                [
                    'check_in_time' => Carbon::today()->setTime(9, 15, 0),
                    'check_in_lat' => $data['lat'] - 0.005,
                    'check_in_lng' => $data['lng'] - 0.005,
                    'check_in_address' => 'Workout Gym Swaroop Nagar, Kanpur',
                    'battery_level' => 98,
                    'total_distance_km' => 14.8,
                    'status' => 'ON_DUTY',
                ]
            );

            // Seed Location History trail
            for ($i = 5; $i >= 0; $i--) {
                LocationHistory::create([
                    'user_id' => $user->id,
                    'latitude' => $data['lat'] - ($i * 0.002),
                    'longitude' => $data['lng'] - ($i * 0.0015),
                    'speed' => $data['speed'],
                    'heading' => $data['heading'],
                    'accuracy' => 6.0,
                    'battery_level' => $data['battery'] + $i,
                    'recorded_at' => Carbon::now()->subMinutes($i * 5),
                ]);
            }
        }

        // 3. Create Sample Shops with Geofence
        $shopsData = [
            [
                'name' => 'Workout Gym & Fitness Center',
                'owner_name' => 'Amit Verma',
                'phone' => '+91 98390 11223',
                'address' => 'Plot 14, Near Arya Nagar Crossing, Swaroop Nagar, Kanpur',
                'latitude' => 26.4850,
                'longitude' => 80.3150,
                'geofence_radius_meters' => 100,
                'qr_code' => 'GYM-KNP-001',
                'category' => 'FITNESS',
                'status' => 'ACTIVE',
            ],
            [
                'name' => 'Z Square Mall Mega Store',
                'owner_name' => 'Kishore Agrawal',
                'phone' => '+91 98390 22334',
                'address' => '16/113 MG Road, Civil Lines, Kanpur',
                'latitude' => 26.4725,
                'longitude' => 80.3522,
                'geofence_radius_meters' => 120,
                'qr_code' => 'SHP-KNP-002',
                'category' => 'SUPERMARKET',
                'status' => 'ACTIVE',
            ],
            [
                'name' => 'Kanpur Tilak Nagar (FF Sports)',
                'owner_name' => 'Deepak Ahuja',
                'phone' => '+91 98390 33445',
                'address' => 'Plot 45, Tilak Nagar, Kanpur',
                'latitude' => 26.490745,
                'longitude' => 80.318524,
                'geofence_radius_meters' => 100,
                'qr_code' => 'SHP-KNP-003',
                'category' => 'RETAIL',
                'status' => 'ACTIVE',
            ],
            [
                'name' => 'Anytime Fitness & Crossfit Kakadeo',
                'owner_name' => 'Suresh Yadav',
                'phone' => '+91 98390 44556',
                'address' => 'Deoki Palace Crossing, Kakadeo, Kanpur',
                'latitude' => 26.4812,
                'longitude' => 80.2928,
                'geofence_radius_meters' => 100,
                'qr_code' => 'GYM-KNP-004',
                'category' => 'FITNESS',
                'status' => 'ACTIVE',
            ],
            [
                'name' => 'Company Bagh Retail Outlet',
                'owner_name' => 'Harish Chandra',
                'phone' => '+91 98390 55555',
                'address' => 'Near Phool Bagh / Company Bagh, Kanpur',
                'latitude' => 26.490963,
                'longitude' => 80.316120,
                'geofence_radius_meters' => 90,
                'qr_code' => 'SHP-KNP-005',
                'category' => 'RETAIL',
                'status' => 'ACTIVE',
            ],
        ];

        $createdShops = [];

        foreach ($shopsData as $s) {
            $shop = Shop::updateOrCreate(
                ['qr_code' => $s['qr_code']],
                array_merge($s, ['created_by' => $admin->id])
            );
            $createdShops[] = $shop;
        }

        // 4. Assign Shops to Employees & Seed Sample Visits
        if (!empty($createdEmployees) && !empty($createdShops)) {
            // Assign shops to Rahul Sharma
            $createdEmployees[0]->shops()->sync([$createdShops[0]->id, $createdShops[1]->id, $createdShops[3]->id]);

            // Rahul's Completed Visit
            Visit::create([
                'user_id' => $createdEmployees[0]->id,
                'shop_id' => $createdShops[0]->id,
                'check_in_time' => Carbon::today()->setTime(10, 30, 0),
                'check_out_time' => Carbon::today()->setTime(11, 15, 0),
                'check_in_lat' => 28.6327,
                'check_in_lng' => 77.2196,
                'check_out_lat' => 28.6328,
                'check_out_lng' => 77.2197,
                'purpose' => 'ORDER_COLLECTION',
                'outcome' => 'ORDER_PLACED',
                'order_amount' => 45500.00,
                'is_verified_geofence' => true,
                'distance_from_shop_meters' => 12.5,
                'status' => 'COMPLETED',
                'notes' => 'Received stock replenishment order for 50 cases of premium FMCG inventory.',
            ]);

            // Rahul's Ongoing Visit
            Visit::create([
                'user_id' => $createdEmployees[0]->id,
                'shop_id' => $createdShops[1]->id,
                'check_in_time' => Carbon::now()->subMinutes(25),
                'check_in_lat' => 28.6274,
                'check_in_lng' => 77.2271,
                'purpose' => 'PAYMENT_RECOVERY',
                'is_verified_geofence' => true,
                'distance_from_shop_meters' => 15.0,
                'status' => 'STARTED',
                'notes' => 'Discussing pending invoice clearance with account manager.',
            ]);
        }
    }
}
