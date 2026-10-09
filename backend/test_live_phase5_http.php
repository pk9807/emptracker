<?php

echo "\n=======================================================\n";
echo "       EMPTRACKER AI PHASE 5 HTTP API VERIFICATION      \n";
echo "=======================================================\n\n";

$passed = 0;
$failed = 0;

function runCurl($url, $method = 'GET', $data = null, $token = null) {
    $headers = [
        "Accept: application/json",
        "Content-Type: application/json",
    ];
    if ($token) {
        $headers[] = "Authorization: Bearer {$token}";
    }
    
    $opts = [
        'http' => [
            'method' => $method,
            'header' => implode("\r\n", $headers),
            'ignore_errors' => true,
        ],
    ];
    if ($data !== null) {
        $opts['http']['content'] = json_encode($data);
    }
    
    $ctx = stream_context_create($opts);
    $resp = @file_get_contents($url, false, $ctx);
    
    $httpCode = 200;
    if (isset($http_response_header) && is_array($http_response_header)) {
        foreach ($http_response_header as $header) {
            if (preg_match('#HTTP/[0-9\.]+\s+([0-9]+)#', $header, $matches)) {
                $httpCode = (int)$matches[1];
            }
        }
    }
    
    return [
        'code' => $httpCode,
        'body' => json_decode($resp, true),
        'raw' => $resp,
    ];
}

function assertTest($condition, $label, &$passed, &$failed) {
    if ($condition) {
        echo "  [PASS] {$label}\n";
        $passed++;
    } else {
        echo "  [FAIL] {$label}\n";
        $failed++;
    }
}

$baseUrl = 'http://localhost/emptracker/backend/public/index.php/api';

// 1. Health Check
$health = runCurl("{$baseUrl}/ai/health");
assertTest($health['code'] === 200 && ($health['body']['status'] ?? '') === 'success', "GET /api/ai/health returns 200 OK", $passed, $failed);
assertTest(($health['body']['data']['ai_enabled'] ?? false) === true, "AI Gateway is enabled in environment", $passed, $failed);
assertTest(($health['body']['data']['local_ai']['enabled'] ?? false) === true, "Local AI provider is enabled (Qwen2.5)", $passed, $failed);

// 2. Admin Login
$adminLogin = runCurl("{$baseUrl}/auth/login", 'POST', [
    'email' => 'admin@fieldforce.com',
    'password' => 'Admin@123456',
]);
$adminToken = $adminLogin['body']['data']['token'] ?? null;
assertTest($adminLogin['code'] === 200 && !empty($adminToken), "Admin authenticated successfully", $passed, $failed);

// 3. Employee Login
$empLogin = runCurl("{$baseUrl}/auth/login", 'POST', [
    'email' => 'rahul@fieldforce.com',
    'password' => 'Emp@123456',
]);
$empToken = $empLogin['body']['data']['token'] ?? null;
assertTest($empLogin['code'] === 200 && !empty($empToken), "Employee authenticated successfully", $passed, $failed);

// 4. Admin Tools List
$toolsResp = runCurl("{$baseUrl}/ai/tools", 'GET', null, $adminToken);
$toolsList = $toolsResp['body']['data']['tools'] ?? [];
assertTest($toolsResp['code'] === 200 && count($toolsList) >= 17, "GET /api/ai/tools returns 17 registered tools (Found: " . count($toolsList) . ")", $passed, $failed);

// Check Phase 5 map tools exist in registry list
$toolNames = array_column($toolsList, 'name');
assertTest(in_array('get_overdue_shops', $toolNames), "Tool 'get_overdue_shops' exists in registry", $passed, $failed);
assertTest(in_array('get_next_shop_recommendation', $toolNames), "Tool 'get_next_shop_recommendation' exists in registry", $passed, $failed);
assertTest(in_array('get_employee_route_summary', $toolNames), "Tool 'get_employee_route_summary' exists in registry", $passed, $failed);
assertTest(in_array('get_area_coverage_summary', $toolNames), "Tool 'get_area_coverage_summary' exists in registry", $passed, $failed);

// 5. Test Chat Intent - Overdue Shops
$overdueChat = runCurl("{$baseUrl}/ai/chat", 'POST', [
    'message' => 'Kaunse shops 7 din se visit nahi hue?',
], $adminToken);
assertTest($overdueChat['code'] === 200, "POST /api/ai/chat for overdue shops returns 200 OK", $passed, $failed);
assertTest(!empty($overdueChat['body']['data']['message']), "Overdue shops returned AI response text", $passed, $failed);
assertTest(isset($overdueChat['body']['data']['data']['get_overdue_shops']), "Overdue shops returned structured tool data & map entities", $passed, $failed);

// 6. Test Chat Intent - Route Summary
$routeChat = runCurl("{$baseUrl}/ai/chat", 'POST', [
    'message' => 'Ravi ka aaj ka route summarize karo.',
], $adminToken);
assertTest($routeChat['code'] === 200, "POST /api/ai/chat for route summary returns 200 OK", $passed, $failed);
assertTest(!empty($routeChat['body']['data']['message']), "Route summary returned AI explanation", $passed, $failed);

// 7. Test Chat Intent - Next Shop Recommendation
$nextShopChat = runCurl("{$baseUrl}/ai/chat", 'POST', [
    'message' => 'Kaunsa shop sabse pehle visit karna chahiye?',
], $adminToken);
assertTest($nextShopChat['code'] === 200, "POST /api/ai/chat for next shop recommendation returns 200 OK", $passed, $failed);
assertTest(!empty($nextShopChat['body']['data']['message']), "Next shop recommendation returned AI response", $passed, $failed);

// 8. Test Chat Intent - Area Coverage
$coverageChat = runCurl("{$baseUrl}/ai/chat", 'POST', [
    'message' => 'Show area shop coverage summary for Civil Lines',
], $adminToken);
assertTest($coverageChat['code'] === 200, "POST /api/ai/chat for area coverage returns 200 OK", $passed, $failed);
assertTest(!empty($coverageChat['body']['data']['message']), "Area coverage returned AI response", $passed, $failed);

echo "\n-------------------------------------------------------\n";
echo "RESULTS: {$passed} Passed, {$failed} Failed\n";
echo "=======================================================\n\n";

exit($failed > 0 ? 1 : 0);
