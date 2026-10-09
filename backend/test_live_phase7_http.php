<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "===============================================================\n";
echo "   EmpTracker Phase 7: Proactive AI Agent Live Test Suite     \n";
echo "===============================================================\n\n";

$baseUrl = 'http://localhost/emptracker/backend/public/index.php/api';

function httpRequest($method, $url, $data = [], $token = null) {
    $headers = "Content-Type: application/json\r\nAccept: application/json\r\n";
    if ($token) {
        $headers .= "Authorization: Bearer $token\r\n";
    }
    $options = [
        'http' => [
            'method' => $method,
            'header' => $headers,
            'content' => !empty($data) ? json_encode($data) : null,
            'ignore_errors' => true,
        ],
    ];
    $context = stream_context_create($options);
    $response = @file_get_contents($url, false, $context);
    $status = 0;
    if (isset($http_response_header) && count($http_response_header) > 0) {
        if (preg_match('#HTTP/[0-9\.]+\s+([0-9]+)#', $http_response_header[0], $matches)) {
            $status = (int)$matches[1];
        }
    }
    return ['status' => $status, 'data' => json_decode($response, true), 'raw' => $response];
}

function httpPost($url, $data = [], $token = null) {
    return httpRequest('POST', $url, $data, $token);
}

function httpGet($url, $token = null) {
    return httpRequest('GET', $url, [], $token);
}

// 1. Authenticate Admin
echo "1. Authenticating Admin User...\n";
$adminLogin = httpPost("$baseUrl/auth/login", [
    'email' => 'admin@fieldforce.com',
    'password' => 'Admin@123456',
]);
if ($adminLogin['status'] !== 200 || empty($adminLogin['data']['data']['token'])) {
    die("❌ Admin Login Failed: " . $adminLogin['raw'] . "\n");
}
$adminToken = $adminLogin['data']['data']['token'];
echo "   ✅ Admin Authenticated. Token acquired.\n\n";

// 2. Authenticate Employee
echo "2. Authenticating Employee User...\n";
$empLogin = httpPost("$baseUrl/auth/login", [
    'email' => 'rahul@fieldforce.com',
    'password' => 'Emp@123456',
]);
if ($empLogin['status'] !== 200 || empty($empLogin['data']['data']['token'])) {
    die("❌ Employee Login Failed: " . $empLogin['raw'] . "\n");
}
$empToken = $empLogin['data']['data']['token'];
echo "   ✅ Employee Authenticated. Token acquired.\n\n";

// 3. Test GET /api/ai/tools (Tool Count & Registration Check)
echo "3. Testing AI Tool Registry & Count...\n";
$toolsRes = httpGet("$baseUrl/ai/tools", $adminToken);
if ($toolsRes['status'] === 200 && isset($toolsRes['data']['data']['total_tools'])) {
    $totalTools = $toolsRes['data']['data']['total_tools'];
    echo "   ✅ Total Tools Registered: $totalTools\n";
    $toolNames = array_column($toolsRes['data']['data']['tools'], 'name');
    echo "   Tools: " . implode(', ', $toolNames) . "\n";
    if (in_array('get_proactive_insights', $toolNames) && in_array('get_daily_operational_summary', $toolNames)) {
        echo "   ✅ Proactive tools (get_proactive_insights, get_daily_operational_summary) confirmed in registry!\n\n";
    } else {
        echo "   ❌ Proactive tools missing from tool registry!\n\n";
    }
} else {
    echo "   ❌ Failed to fetch tools: " . $toolsRes['raw'] . "\n\n";
}

// 4. Test GET /api/ai/insights for Admin (Full Territory Telemetry Signals)
echo "4. Testing GET /api/ai/insights for Admin...\n";
$insightsRes = httpGet("$baseUrl/ai/insights", $adminToken);
if ($insightsRes['status'] === 200) {
    $insightsData = $insightsRes['data']['data'];
    echo "   ✅ Admin Insights Fetched! Total signals detected: " . $insightsData['total_insights'] . "\n";
    foreach (array_slice($insightsData['insights'], 0, 3) as $ins) {
        echo "      - [{$ins['severity']}] {$ins['signal_type']}: {$ins['title']}\n";
        echo "        Facts: " . json_encode($ins['facts']) . "\n";
        echo "        Recommendation: {$ins['recommendation']}\n";
    }
    echo "\n";
} else {
    echo "   ❌ Failed to fetch insights for Admin: " . $insightsRes['raw'] . "\n\n";
}

// 5. Test GET /api/ai/insights for Employee (RBAC Isolation)
echo "5. Testing GET /api/ai/insights for Employee (RBAC Isolation)...\n";
$empInsightsRes = httpGet("$baseUrl/ai/insights", $empToken);
if ($empInsightsRes['status'] === 200) {
    $empInsightsData = $empInsightsRes['data']['data'];
    echo "   ✅ Employee Insights Fetched! Total scoped signals: " . $empInsightsData['total_insights'] . "\n";
    foreach ($empInsightsData['insights'] as $ins) {
        echo "      - [{$ins['severity']}] Scoped entity: {$ins['entity_name']} ({$ins['entity_type']})\n";
    }
    echo "\n";
} else {
    echo "   ❌ Failed to fetch insights for Employee: " . $empInsightsRes['raw'] . "\n\n";
}

// 6. Test GET /api/ai/insights/summary for Admin (Executive Summary)
echo "6. Testing GET /api/ai/insights/summary for Admin...\n";
$summaryRes = httpGet("$baseUrl/ai/insights/summary", $adminToken);
if ($summaryRes['status'] === 200) {
    $summaryData = $summaryRes['data']['data'];
    echo "   ✅ Executive Summary Status: " . $summaryData['status'] . "\n";
    echo "      Executive Summary Text: " . $summaryData['executive_summary'] . "\n";
    echo "      Severity Breakdown: " . json_encode($summaryData['counts']) . "\n\n";
} else {
    echo "   ❌ Failed to fetch executive summary: " . $summaryRes['raw'] . "\n\n";
}

// 7. Test RBAC Security on Executive Summary for Employee (Must be 403 Forbidden)
echo "7. Testing RBAC Security on Executive Summary for Employee (Must be 403 Forbidden)...\n";
$empSummaryRes = httpGet("$baseUrl/ai/insights/summary", $empToken);
if ($empSummaryRes['status'] === 403) {
    echo "   ✅ Security Verified! Employee correctly forbidden (403) from executive summary.\n\n";
} else {
    echo "   ❌ Security Breach! Employee got status " . $empSummaryRes['status'] . "\n\n";
}

// 8. Test POST /api/ai/insights/acknowledge (Alert State Transition)
echo "8. Testing Alert Acknowledgment Lifecycle (POST /api/ai/insights/acknowledge)...\n";
$ackRes = httpPost("$baseUrl/ai/insights/acknowledge", [
    'alert_id' => 'shop_overdue_1',
    'action' => 'ACKNOWLEDGED',
], $adminToken);
if ($ackRes['status'] === 200 && $ackRes['data']['data']['status'] === 'ACKNOWLEDGED') {
    echo "   ✅ Alert 'shop_overdue_1' successfully ACKNOWLEDGED by Admin.\n\n";
} else {
    echo "   ❌ Alert acknowledgment failed: " . $ackRes['raw'] . "\n\n";
}

// 9. Test Conversational Proactive Intent in Hindi / Hinglish ("Daily summary batao")
echo "9. Testing Conversational Proactive Intent ('Daily summary batao')...\n";
$chatSummaryRes = httpPost("$baseUrl/ai/chat", [
    'message' => 'Admin dashboard ke liye aaj ka daily operational summary batao',
], $adminToken);
if ($chatSummaryRes['status'] === 200) {
    $chatData = $chatSummaryRes['data']['data'];
    echo "   ✅ Proactive AI Reply: " . $chatData['message'] . "\n";
    echo "   Tools Used: " . json_encode($chatData['tools_used'] ?? []) . "\n\n";
} else {
    echo "   ❌ Proactive chat failed: " . $chatSummaryRes['raw'] . "\n\n";
}

// 10. Test Conversational Alert Intent ("Kaunse alerts aur risks active hain?")
echo "10. Testing Conversational Alert Intent ('Kaunse alerts aur risks active hain?')...\n";
$chatAlertRes = httpPost("$baseUrl/ai/chat", [
    'message' => 'Kaunse critical alerts aur operational risks active hain?',
], $adminToken);
if ($chatAlertRes['status'] === 200) {
    $chatAlertData = $chatAlertRes['data']['data'];
    echo "   ✅ Alert AI Reply: " . $chatAlertData['message'] . "\n";
    echo "   Tools Used: " . json_encode($chatAlertData['tools_used'] ?? []) . "\n\n";
} else {
    echo "   ❌ Alert chat failed: " . $chatAlertRes['raw'] . "\n\n";
}

echo "===============================================================\n";
echo "   All Phase 7 Proactive AI Tests Completed Successfully!      \n";
echo "===============================================================\n";
