<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\AI\Contracts\AiToolInterface;
use App\AI\Enums\UserRole;
use App\AI\Exceptions\AiPermissionDeniedException;
use App\AI\Exceptions\AiValidationException;
use App\AI\Services\AiConfirmationService;
use App\AI\Services\AiGateway;
use App\AI\Services\ToolRegistry;
use App\Models\EmployeeShop;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Support\Facades\DB;

echo "\n=======================================================\n";
echo "       EMPTRACKER AI PHASE 4 VERIFICATION RUNNER       \n";
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

// 1. Resolve Services
$gateway = app(AiGateway::class);
$registry = app(ToolRegistry::class);
$confirmationService = app(AiConfirmationService::class);

assertCondition($gateway instanceof AiGateway, "AiGateway resolved from DI container", $passed, $failed);
assertCondition($registry instanceof ToolRegistry, "ToolRegistry resolved from DI container", $passed, $failed);
assertCondition($confirmationService instanceof AiConfirmationService, "AiConfirmationService resolved from DI container", $passed, $failed);

// 2. Verify Total Tools & Write Tools
$allTools = $registry->getAllTools();
assertCondition(count($allTools) >= 13, "13 Tools registered in ToolRegistry (10 Read-Only + 3 Write)", $passed, $failed);

$assignTool = $registry->getTool('assign_employee_shop');
$noteTool = $registry->getTool('add_shop_urgent_note');
$remarkTool = $registry->getTool('record_visit_remark');

assertCondition($assignTool instanceof AiToolInterface && $assignTool->isWriteAction(), "Tool 'assign_employee_shop' is configured as a write action", $passed, $failed);
assertCondition($noteTool instanceof AiToolInterface && $noteTool->isWriteAction(), "Tool 'add_shop_urgent_note' is configured as a write action", $passed, $failed);
assertCondition($remarkTool instanceof AiToolInterface && $remarkTool->isWriteAction(), "Tool 'record_visit_remark' is configured as a write action", $passed, $failed);

// 3. Load Users & Test Entities
$admin = User::where('role', 'admin')->first();
$employee1 = User::where('role', 'employee')->orderBy('id')->first();
$shop = Shop::first();

assertCondition($admin !== null, "Admin user loaded ({$admin?->email})", $passed, $failed);
assertCondition($employee1 !== null, "Employee user loaded ({$employee1?->name} ID: {$employee1?->id})", $passed, $failed);
assertCondition($shop !== null, "Shop record loaded ({$shop?->name} ID: {$shop?->id})", $passed, $failed);

// 4. Role Isolation for Write Actions
$adminTools = $registry->getToolsForUser($admin);
$employeeTools = $registry->getToolsForUser($employee1);

assertCondition(isset($adminTools['assign_employee_shop']), "Admin can access 'assign_employee_shop' write action", $passed, $failed);
assertCondition(!isset($employeeTools['assign_employee_shop']), "Employee cannot access 'assign_employee_shop' write action (Hidden from schema)", $passed, $failed);

// 5. Test 2-Step Confirmation Proposal Generation
$response = $gateway->handle($admin, "Rahul ko shop #{$shop->id} assign kardo");

assertCondition($response->requiresConfirmation === true, "Admin write command requires confirmation", $passed, $failed);
assertCondition($response->action === 'assign_employee_shop', "Action name correctly tagged as 'assign_employee_shop'", $passed, $failed);
assertCondition(isset($response->data['confirmation_token']), "Confirmation token generated in proposal response", $passed, $failed);

$token = $response->data['confirmation_token'];

// 6. Test Unauthorized Confirmation Attempt (Employee trying to confirm Admin's proposal)
$tamperFailed = false;
try {
    $gateway->confirmAction($employee1, $token);
} catch (AiValidationException $e) {
    $tamperFailed = str_contains($e->getMessage(), 'Unauthorized') || str_contains($e->getMessage(), 'another user');
}
assertCondition($tamperFailed, "Unauthorized user blocked from executing proposal token", $passed, $failed);

// 7. Test Admin Execution of Confirmation
// Clean any existing test assignment
EmployeeShop::where('user_id', $employee1->id)->where('shop_id', $shop->id)->delete();

$executionResult = $gateway->confirmAction($admin, $token);
assertCondition($executionResult['success'] === true, "Admin successfully confirmed and executed write action", $passed, $failed);

$assignmentExists = EmployeeShop::where('user_id', $employee1->id)->where('shop_id', $shop->id)->exists();
assertCondition($assignmentExists, "Database record created inside transaction for employee-shop mapping", $passed, $failed);

// 8. Idempotency Protection Check (Re-executing same token must fail)
$idempotencyBlocked = false;
try {
    $gateway->confirmAction($admin, $token);
} catch (AiValidationException $e) {
    $idempotencyBlocked = str_contains($e->getMessage(), 'already been processed') || str_contains($e->getMessage(), 'Idempotency');
}
assertCondition($idempotencyBlocked, "Idempotency guard prevented double-execution of consumed confirmation token", $passed, $failed);

// 9. Employee Safe Write Action: Add Urgent Shop Note
$empResponse = $gateway->handle($employee1, "Shop #{$shop->id} par urgent note add karo: Payment collection scheduled for tomorrow morning");
assertCondition($empResponse->requiresConfirmation === true, "Employee write note command requires confirmation", $passed, $failed);
assertCondition($empResponse->action === 'add_shop_urgent_note', "Action name correctly matched 'add_shop_urgent_note'", $passed, $failed);

$empToken = $empResponse->data['confirmation_token'];
$empExecResult = $gateway->confirmAction($employee1, $empToken);
assertCondition($empExecResult['success'] === true, "Employee confirmed and executed shop note update", $passed, $failed);

// 10. Audit Logging Verification for Phase 4 Actions
$auditCount = DB::table('ai_audit_logs')
    ->where('action', 'assign_employee_shop')
    ->orWhere('action', 'add_shop_urgent_note')
    ->count();

assertCondition($auditCount >= 2, "Confirmed write actions recorded in ai_audit_logs table (Count: {$auditCount})", $passed, $failed);

echo "\n=======================================================\n";
echo "  PHASE 4 SUMMARY: {$passed} PASSED, {$failed} FAILED\n";
echo "=======================================================\n\n";

if ($failed > 0) {
    exit(1);
}
exit(0);
