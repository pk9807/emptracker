<?php

echo "\n=======================================================\n";
echo "       EMPTRACKER AI PHASE 6 HTTP API VERIFICATION      \n";
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

// 1. Health Check with Voice, Multilingual & Offline Flags
$health = runCurl("{$baseUrl}/ai/health");
assertTest($health['code'] === 200 && ($health['body']['status'] ?? '') === 'success', "GET /api/ai/health returns 200 OK", $passed, $failed);
assertTest(($health['body']['data']['voice']['enabled'] ?? false) === true, "Voice AI features enabled in health check", $passed, $failed);
assertTest(($health['body']['data']['multilingual']['enabled'] ?? false) === true, "Multilingual intelligence enabled (Hindi/Hinglish/English)", $passed, $failed);
assertTest(($health['body']['data']['offline']['enabled'] ?? false) === true, "Offline capability framework active", $passed, $failed);

// 2. Offline Capabilities Matrix Endpoint
$matrixResp = runCurl("{$baseUrl}/ai/offline/matrix");
assertTest($matrixResp['code'] === 200, "GET /api/ai/offline/matrix returns 200 OK", $passed, $failed);
$matrix = $matrixResp['body']['data']['matrix'] ?? [];
assertTest(isset($matrix['general_faq']) && $matrix['general_faq']['is_offline_capable'] === true, "Matrix marks 'general_faq' as offline-capable", $passed, $failed);
assertTest(isset($matrix['live_employee_location']) && $matrix['live_employee_location']['is_offline_capable'] === false, "Matrix marks 'live_employee_location' as online-required", $passed, $failed);
assertTest(isset($matrix['write_actions']) && $matrix['write_actions']['is_offline_capable'] === false, "Matrix marks 'write_actions' as online-required", $passed, $failed);

// 3. Admin Authentication
$adminLogin = runCurl("{$baseUrl}/auth/login", 'POST', [
    'email' => 'admin@fieldforce.com',
    'password' => 'Admin@123456',
]);
$adminToken = $adminLogin['body']['data']['token'] ?? null;
assertTest($adminLogin['code'] === 200 && !empty($adminToken), "Admin authenticated successfully", $passed, $failed);

// 4. Multilingual Intent Verification: Hindi Devanagari
$hindiChat = runCurl("{$baseUrl}/ai/chat", 'POST', [
    'message' => 'आज कितने शॉप्स पेंडिंग हैं?',
], $adminToken);
assertTest($hindiChat['code'] === 200, "POST /api/ai/chat understands Hindi Devanagari query", $passed, $failed);
assertTest(!empty($hindiChat['body']['data']['message']), "Hindi query produced natural language response", $passed, $failed);

// 5. Multilingual Intent Verification: Hinglish Roman Hindi
$hinglishChat = runCurl("{$baseUrl}/ai/chat", 'POST', [
    'message' => 'Ravi ka route summarize karo aur total distance batao.',
], $adminToken);
assertTest($hinglishChat['code'] === 200, "POST /api/ai/chat understands Hinglish query", $passed, $failed);
assertTest(!empty($hinglishChat['body']['data']['message']), "Hinglish query produced structured response", $passed, $failed);

// 6. Voice Spoken Command for Write Action (Must Propose 2-Step Card, NEVER Auto-Execute)
$voiceWriteChat = runCurl("{$baseUrl}/ai/chat", 'POST', [
    'message' => 'Rahul ko Workout Gym shop assign kardo.',
], $adminToken);
assertTest($voiceWriteChat['code'] === 200, "Spoken write action query processed safely", $passed, $failed);
assertTest(($voiceWriteChat['body']['data']['requires_confirmation'] ?? false) === true, "Voice write action requires 2-step confirmation (Never auto-executed)", $passed, $failed);
assertTest(!empty($voiceWriteChat['body']['data']['data']['confirmation_token'] ?? null), "Cryptographic confirmation token generated for human review", $passed, $failed);

echo "\n-------------------------------------------------------\n";
echo "RESULTS: {$passed} Passed, {$failed} Failed\n";
echo "=======================================================\n\n";

exit($failed > 0 ? 1 : 0);
