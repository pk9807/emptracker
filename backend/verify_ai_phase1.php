<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\AI\Contracts\AiAuditServiceInterface;
use App\AI\DTOs\AiRequest;
use App\AI\Enums\UserRole;
use App\AI\Exceptions\AiDisabledException;
use App\AI\Exceptions\AiPermissionDeniedException;
use App\AI\Services\AiGateway;
use App\AI\Services\AiPermissionService;
use App\AI\Services\ToolRegistry;
use App\Models\User;

echo "=======================================================\n";
echo "       EMPTRACKER AI PHASE 1 VERIFICATION RUNNER       \n";
echo "=======================================================\n\n";

$passCount = 0;
$failCount = 0;

function assertCondition(bool $condition, string $testName) {
    global $passCount, $failCount;
    if ($condition) {
        echo "  [PASS] $testName\n";
        $passCount++;
    } else {
        echo "  [FAIL] $testName\n";
        $failCount++;
    }
}

// 1. DI Container Resolution
$gateway = app(AiGateway::class);
$registry = app(ToolRegistry::class);
$permissionService = app(AiPermissionService::class);

assertCondition($gateway instanceof AiGateway, "AiGateway resolved from DI container");
assertCondition($registry instanceof ToolRegistry, "ToolRegistry resolved from DI container");
assertCondition(count($registry->getAllTools()) >= 10, "10+ Tools registered in ToolRegistry");

// 2. Fetch Users
$admin = User::where('role', 'admin')->first();
$employee1 = User::where('role', 'employee')->where('id', 2)->first();
$employee2 = User::where('role', 'employee')->where('id', 3)->first();

assertCondition($admin !== null, "Admin user loaded ({$admin->email})");
assertCondition($employee1 !== null, "Employee 1 loaded ({$employee1->name} ID: {$employee1->id})");
assertCondition($employee2 !== null, "Employee 2 loaded ({$employee2->name} ID: {$employee2->id})");

// 3. Role-based Tool Accessibility
$adminTools = $registry->getToolsForUser($admin);
$empTools = $registry->getToolsForUser($employee1);

assertCondition(count($adminTools) >= 10, "Admin can access all registered tools");
assertCondition(count($empTools) >= 9, "Employee can access employee tools");
assertCondition(!isset($empTools['search_employees']), "search_employees is hidden from Employee");

// 4. Employee Isolation Check (Employee 1 trying to access Employee 2 data)
$isolationBlocked = false;
try {
    $getAttendanceTool = $registry->getTool('get_employee_attendance');
    $params = ['employee_id' => $employee2->id];
    $permissionService->enforceEmployeeIsolation($employee1, $params);
} catch (AiPermissionDeniedException $e) {
    $isolationBlocked = true;
}
assertCondition($isolationBlocked, "Employee 1 blocked from querying Employee 2's data (AiPermissionDeniedException thrown)");

// 5. Admin can inspect any employee
$adminAllowed = true;
try {
    $params = ['employee_id' => $employee1->id];
    $permissionService->enforceEmployeeIsolation($admin, $params);
} catch (AiPermissionDeniedException $e) {
    $adminAllowed = false;
}
assertCondition($adminAllowed, "Admin permitted to inspect any employee");

// 6. Test All 10 Read-Only Tools Execution
$toolExecutionPass = true;
$testCases = [
    'search_employees' => [$admin, ['is_active' => true, 'limit' => 5]],
    'get_employee_profile' => [$employee1, ['employee_id' => $employee1->id]],
    'get_employee_location' => [$employee1, ['employee_id' => $employee1->id]],
    'get_employee_attendance' => [$employee1, ['employee_id' => $employee1->id]],
    'get_employee_visits' => [$employee1, ['employee_id' => $employee1->id]],
    'search_shops' => [$employee1, ['query' => 'Gym']],
    'get_shop_details' => [$employee1, ['shop_id' => 13]],
    'get_shop_visits' => [$employee1, ['shop_id' => 13]],
    'get_nearby_shops' => [$employee1, ['latitude' => 26.4499, 'longitude' => 80.3319, 'radius_km' => 20]],
    'get_today_route' => [$employee1, ['employee_id' => $employee1->id]],
];

foreach ($testCases as $toolName => [$actor, $params]) {
    $tool = $registry->getTool($toolName);
    $res = $tool->execute($actor, $params);
    assertCondition($res->isSuccess, "Tool '{$toolName}' executed successfully");
}

// 7. Full Gateway Handling with Natural Language (Hindi, Hinglish, English)
$hindiQuery = $gateway->handle($employee1, "Mere aaj kitne shops pending hain?");
assertCondition(
    $hindiQuery->type->value === 'answer' && str_contains($hindiQuery->message, 'shops assigned'),
    "Gateway handled Hindi/Hinglish route query with local synthesis"
);

$englishNearby = $gateway->handle($employee1, "Show nearby shops close to me", [
    'client_context' => ['latitude' => 26.485, 'longitude' => 80.315]
]);
assertCondition(
    $englishNearby->type->value === 'answer' && in_array('get_nearby_shops', $englishNearby->toolsUsed),
    "Gateway handled English nearby query with spatial tool execution"
);

// 8. Audit Log Persistence Check
$auditCount = \Illuminate\Support\Facades\DB::table('ai_audit_logs')->count();
assertCondition($auditCount > 0, "AI audit log entries recorded in database (Total logs: {$auditCount})");

echo "\n=======================================================\n";
echo "  SUMMARY: {$passCount} PASSED, {$failCount} FAILED\n";
echo "=======================================================\n";

exit($failCount > 0 ? 1 : 0);
