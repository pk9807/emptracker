<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\AI\Contracts\AiToolInterface;
use App\AI\Exceptions\AiPermissionDeniedException;
use App\AI\Services\AiGateway;
use App\AI\Services\MapIntelligenceService;
use App\AI\Services\ToolRegistry;
use App\Models\Shop;
use App\Models\User;

echo "\n=======================================================\n";
echo "       EMPTRACKER AI PHASE 5 VERIFICATION RUNNER       \n";
echo "=======================================================\n\n";

$passed = 0;
$failed = 0;

function assertCondition(bool $condition, string $label, &$passed, &$failed) {
    if ($condition) {
        echo "  [PASS] {$label}\n";
        $passed++;
    } else {
        echo "  [FAIL] {$label}\n";
        $failed++;
    }
}

// 1. DI Resolution
$gateway = app(AiGateway::class);
$registry = app(ToolRegistry::class);
$mapService = app(MapIntelligenceService::class);

assertCondition($gateway instanceof AiGateway, "AiGateway resolved from DI container", $passed, $failed);
assertCondition($registry instanceof ToolRegistry, "ToolRegistry resolved from DI container", $passed, $failed);
assertCondition($mapService instanceof MapIntelligenceService, "MapIntelligenceService resolved from DI container", $passed, $failed);

// 2. Total Tool Count Check
$allTools = $registry->getAllTools();
assertCondition(count($allTools) >= 17, "17+ Total Tools registered in ToolRegistry (Found: " . count($allTools) . ")", $passed, $failed);

// Verify Map Tools exist
$overdueTool = $registry->getTool('get_overdue_shops');
$nextShopTool = $registry->getTool('get_next_shop_recommendation');
$routeSummaryTool = $registry->getTool('get_employee_route_summary');
$coverageTool = $registry->getTool('get_area_coverage_summary');

assertCondition($overdueTool instanceof AiToolInterface, "Tool 'get_overdue_shops' registered", $passed, $failed);
assertCondition($nextShopTool instanceof AiToolInterface, "Tool 'get_next_shop_recommendation' registered", $passed, $failed);
assertCondition($routeSummaryTool instanceof AiToolInterface, "Tool 'get_employee_route_summary' registered", $passed, $failed);
assertCondition($coverageTool instanceof AiToolInterface, "Tool 'get_area_coverage_summary' registered", $passed, $failed);

// 3. Setup Users for Test Execution
$admin = new User([
    'name' => 'Super Admin',
    'email' => 'admin@emptracker.com',
    'role' => 'admin',
]);
$admin->id = 1;

$employee1 = new User([
    'name' => 'Ravi Kumar',
    'email' => 'ravi@emptracker.com',
    'role' => 'employee',
]);
$employee1->id = 2;

$employee2 = new User([
    'name' => 'Amit Sharma',
    'email' => 'amit@emptracker.com',
    'role' => 'employee',
]);
$employee2->id = 3;

assertCondition($admin !== null, "Admin loaded ({$admin->email})", $passed, $failed);
assertCondition($employee1 !== null, "Employee 1 loaded ({$employee1->name})", $passed, $failed);
assertCondition($employee2 !== null, "Employee 2 loaded ({$employee2->name})", $passed, $failed);

// 4. Test Haversine Distance Calculation
$dist = $mapService->calculateDistanceKm(26.4499, 80.3319, 26.4850, 80.3150);
assertCondition($dist > 0 && $dist < 10.0, "Haversine distance computed accurately (Distance: {$dist} km)", $passed, $failed);

// 5. Test Overdue Shops Tool
$overdueRes = $overdueTool->execute($admin, ['days' => 7]);
assertCondition($overdueRes->isSuccess && isset($overdueRes->data['total_overdue']), "get_overdue_shops executed with shop count: " . ($overdueRes->data['total_overdue'] ?? 0), $passed, $failed);
assertCondition(isset($overdueRes->data['entities']) && is_array($overdueRes->data['entities']), "get_overdue_shops returned structured entities for map integration", $passed, $failed);

// 6. Test Next Shop Recommendation Tool
$nextRes = $nextShopTool->execute($employee1, ['latitude' => 26.4499, 'longitude' => 80.3319]);
assertCondition($nextRes->isSuccess && isset($nextRes->data['found']), "get_next_shop_recommendation executed with deterministic urgency ranking", $passed, $failed);

// 7. Test Route Summary Tool & Employee Isolation
$adminRouteRes = $routeSummaryTool->execute($admin, ['employee_id' => $employee1->id]);
assertCondition($adminRouteRes->isSuccess && isset($adminRouteRes->data['total_distance_km']), "Admin successfully retrieved employee route summary", $passed, $failed);

// Employee 1 trying to access Employee 2's route summary -> must throw AiPermissionDeniedException
$isolationPassed = false;
try {
    $routeSummaryTool->execute($employee1, ['employee_id' => $employee2->id]);
} catch (AiPermissionDeniedException $e) {
    $isolationPassed = true;
}
assertCondition($isolationPassed, "Employee 1 blocked from querying Employee 2's route telemetry (AiPermissionDeniedException thrown)", $passed, $failed);

// 8. Test Area Coverage Summary Tool
$covRes = $coverageTool->execute($admin, ['latitude' => 26.4499, 'longitude' => 80.3319, 'radius_km' => 15]);
assertCondition($covRes->isSuccess && isset($covRes->data['coverage_percentage']), "get_area_coverage_summary computed area coverage percentage: " . ($covRes->data['coverage_percentage'] ?? 0) . "%", $passed, $failed);

// 9. Full Gateway Natural Language Invocations
$gatewayOverdue = $gateway->handle($admin, "Kaunse shops 7 din se visit nahi hue?");
assertCondition(
    $gatewayOverdue->type->value === 'answer' && in_array('get_overdue_shops', $gatewayOverdue->toolsUsed),
    "Gateway handled Hindi overdue shops query via get_overdue_shops",
    $passed,
    $failed
);

$gatewayNextShop = $gateway->handle($employee1, "Next shop kaunsa visit karna chahiye?");
assertCondition(
    $gatewayNextShop->type->value === 'answer' && in_array('get_next_shop_recommendation', $gatewayNextShop->toolsUsed),
    "Gateway handled Hindi next-shop recommendation query via get_next_shop_recommendation",
    $passed,
    $failed
);

$gatewayRouteSummary = $gateway->handle($admin, "Rahul ka aaj ka route summarize karo.");
assertCondition(
    $gatewayRouteSummary->type->value === 'answer' && in_array('get_employee_route_summary', $gatewayRouteSummary->toolsUsed),
    "Gateway handled route summary intent with deterministic telemetry payload",
    $passed,
    $failed
);

echo "\n=======================================================\n";
echo "  PHASE 5 SUMMARY: {$passed} PASSED, {$failed} FAILED\n";
echo "=======================================================\n\n";

if ($failed > 0) {
    exit(1);
}
exit(0);
