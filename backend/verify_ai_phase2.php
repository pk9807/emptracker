<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\AI\Contracts\LocalInferenceEngineInterface;
use App\AI\DTOs\AiRequest;
use App\AI\DTOs\AiResponse;
use App\AI\DTOs\AiToolCall;
use App\AI\Enums\DataSensitivity;
use App\AI\Exceptions\AiDisabledException;
use App\AI\Exceptions\AiPermissionDeniedException;
use App\AI\Providers\Engines\QwenLocalInferenceEngine;
use App\AI\Providers\LocalAiProvider;
use App\AI\Services\AiGateway;
use App\AI\Services\AiPermissionService;
use App\AI\Services\AiResponseValidator;
use App\AI\Services\AiRouter;
use App\AI\Services\ToolRegistry;
use App\Models\User;

echo "=======================================================\n";
echo "       EMPTRACKER AI PHASE 2 VERIFICATION RUNNER       \n";
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

// 1. Engine & Provider DI Resolution
$engine = app(LocalInferenceEngineInterface::class);
$localProvider = app(LocalAiProvider::class);
$router = app(AiRouter::class);
$gateway = app(AiGateway::class);
$validator = app(AiResponseValidator::class);

assertCondition($engine instanceof LocalInferenceEngineInterface, "LocalInferenceEngineInterface resolved from DI");
assertCondition($engine->getEngineName() === 'qwen2.5-1.5b-instruct-q4', "Engine model name matches selected Qwen2.5 Q4");
assertCondition($localProvider->isAvailable(), "Local AI Provider is available and active");

$metrics = $engine->getRuntimeMetrics();
assertCondition(isset($metrics['memory_allocated_mb']) && $metrics['quantization'] === 'Q4_K_M', "Engine runtime metrics reporting correctly");

// 2. Load Users
$admin = User::where('role', 'admin')->first();
$employee = User::where('role', 'employee')->first();
assertCondition($admin && $employee, "Loaded admin and employee records for testing");

// 3. Multi-tier Privacy Classification Verification
$reqLocation = AiRequest::create($employee, "Ravi kahan hai?");
$callsLocation = [new AiToolCall('get_employee_location')];
$privacyLoc = $router->classifyPrivacy($reqLocation, $callsLocation);
assertCondition($privacyLoc === DataSensitivity::HIGHLY_SENSITIVE, "Location query classified as HIGHLY_SENSITIVE");
assertCondition(!$privacyLoc->isCloudAllowed(), "HIGHLY_SENSITIVE is prohibited from cloud transmission");

$reqAttendance = AiRequest::create($employee, "Meri attendance batao");
$callsAttendance = [new AiToolCall('get_employee_attendance')];
$privacyAtt = $router->classifyPrivacy($reqAttendance, $callsAttendance);
assertCondition($privacyAtt === DataSensitivity::SENSITIVE, "Attendance query classified as SENSITIVE");
assertCondition(!$privacyAtt->isCloudAllowed(), "SENSITIVE data is prohibited from cloud transmission");

$reqNearby = AiRequest::create($employee, "Show nearby shops");
$callsNearby = [new AiToolCall('get_nearby_shops')];
$privacyNearby = $router->classifyPrivacy($reqNearby, $callsNearby);
assertCondition($privacyNearby === DataSensitivity::INTERNAL, "Nearby shops query classified as INTERNAL");
assertCondition($privacyNearby->isCloudAllowed(), "INTERNAL data allows cloud fallback if enabled");

// 4. Local-First Provider Selection & Cloud Gate
$selectedLoc = $router->selectProvider($reqLocation, $privacyLoc, false);
assertCondition($selectedLoc->getIdentifier() === 'local_qwen_embedded', "Local provider chosen for HIGHLY_SENSITIVE request");

// Attempt to force cloud on sensitive data -> Must fallback safely to local
$blockedCloud = $router->selectProvider($reqLocation, $privacyLoc, true);
assertCondition($blockedCloud->getIdentifier() === 'local_qwen_embedded', "Privacy gate blocked cloud provider for sensitive data");

// 5. Response Validation & Sanitization Tests
$leakTestResponse = AiResponse::answer("User details: password = SecretPassword123, sanctum_token = 12345");
$sanitized = $validator->validate($leakTestResponse);
assertCondition(!str_contains($sanitized->message, 'SecretPassword123'), "Validator redacted sensitive password token");
assertCondition(str_contains($sanitized->message, '[REDACTED]'), "Validator injected [REDACTED] marker");

$sqlLeakResponse = AiResponse::answer("SELECT * FROM users WHERE id = 1");
$sanitizedSql = $validator->validate($sqlLeakResponse);
assertCondition(!str_contains($sanitizedSql->message, 'SELECT * FROM'), "Validator intercepted and redacted raw SQL output");

// 6. Natural Language Synthesis (Hindi, Hinglish, English)
$hindiRes = $gateway->handle($employee, "Mere aaj kitne shops pending hain?");
assertCondition(
    $hindiRes->type->value === 'answer' &&
    in_array('get_today_route', $hindiRes->toolsUsed) &&
    isset($hindiRes->metadata['routing']),
    "Gateway executed Hindi route intent with routing telemetry"
);

$englishRes = $gateway->handle($employee, "Show nearby shops close to me", [
    'client_context' => ['latitude' => 26.485, 'longitude' => 80.315]
]);
assertCondition(
    $englishRes->type->value === 'answer' &&
    in_array('get_nearby_shops', $englishRes->toolsUsed) &&
    $englishRes->metadata['privacy_tier'] === 'internal',
    "Gateway executed English spatial query with internal privacy classification"
);

// 7. Feature Flag Disabled Verification
config(['ai.enabled' => false]);
$disabledThrown = false;
try {
    $gateway->handle($employee, "Hello");
} catch (AiDisabledException $e) {
    $disabledThrown = true;
}
assertCondition($disabledThrown, "AiDisabledException thrown when AI_ENABLED is set to false");
config(['ai.enabled' => true]); // restore

// 8. Phase 1 Regression Checks
$toolRegistry = app(ToolRegistry::class);
assertCondition(count($toolRegistry->getAllTools()) >= 10, "All Phase 1 tools remain intact in registry");

$empTools = $toolRegistry->getToolsForUser($employee);
assertCondition(!isset($empTools['search_employees']) && !isset($empTools['assign_employee_shop']), "Employee still restricted from admin tools (Phase 1 & 4 isolation preserved)");

echo "\n=======================================================\n";
echo "  PHASE 2 SUMMARY: {$passCount} PASSED, {$failCount} FAILED\n";
echo "=======================================================\n";

exit($failCount > 0 ? 1 : 0);
