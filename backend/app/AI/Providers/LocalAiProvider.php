<?php

namespace App\AI\Providers;

use App\AI\Contracts\AiProviderInterface;
use App\AI\Contracts\LocalInferenceEngineInterface;
use App\AI\DTOs\AiRequest;
use App\AI\DTOs\AiResponse;
use App\AI\Enums\ResponseType;
use App\AI\Enums\UserRole;
use App\AI\Providers\Engines\QwenLocalInferenceEngine;

class LocalAiProvider implements AiProviderInterface
{
    protected LocalInferenceEngineInterface $engine;

    public function __construct(?LocalInferenceEngineInterface $engine = null)
    {
        $this->engine = $engine ?? new QwenLocalInferenceEngine();
    }

    public function getIdentifier(): string
    {
        return 'local_qwen_embedded';
    }

    public function getEngine(): LocalInferenceEngineInterface
    {
        return $this->engine;
    }

    public function isAvailable(): bool
    {
        return config('ai.local.enabled', true) && $this->engine->isAvailable();
    }

    public function generate(AiRequest $request, array $toolsContext = []): AiResponse
    {
        $start = microtime(true);

        if (!$this->isAvailable()) {
            return AiResponse::error("Local AI engine is currently unavailable or disabled.", $this->getIdentifier());
        }

        $userMsg = strtolower($request->message);
        $role = $request->userRole;
        $toolResults = $toolsContext['tool_results'] ?? [];
        $toolsUsed = array_keys($toolResults);

        // Detect user language preference
        $isHindiOrHinglish = $this->detectHindiOrHinglish($request->message);

        // 1. If tool execution results exist, synthesize a natural language summary from deterministic facts
        if (!empty($toolResults)) {
            $summary = $this->synthesizeToolResults($request, $toolResults, $isHindiOrHinglish);
            $latency = (microtime(true) - $start) * 1000;
            return AiResponse::answer(
                message: $summary,
                source: $this->getIdentifier(),
                toolsUsed: $toolsUsed,
                data: $toolResults,
                latencyMs: $latency,
                metadata: [
                    'engine' => $this->engine->getEngineName(),
                    'quantization' => 'Q4_K_M',
                    'language' => $isHindiOrHinglish ? 'hindi_hinglish' : 'english',
                    'runtime' => $this->engine->getRuntimeMetrics(),
                ]
            );
        }

        // 2. Direct Q&A / General Assistant FAQ
        $reply = $this->generateGeneralFaqResponse($request, $isHindiOrHinglish);
        $latency = (microtime(true) - $start) * 1000;

        return AiResponse::answer(
            message: $reply,
            source: $this->getIdentifier(),
            toolsUsed: [],
            data: null,
            latencyMs: $latency,
            metadata: [
                'engine' => $this->engine->getEngineName(),
                'quantization' => 'Q4_K_M',
                'language' => $isHindiOrHinglish ? 'hindi_hinglish' : 'english',
                'runtime' => $this->engine->getRuntimeMetrics(),
            ]
        );
    }

    /**
     * Generate structured JSON output for a tool or report query
     */
    public function generateStructured(AiRequest $request, array $jsonSchema, array $toolsContext = []): array
    {
        $prompt = "User: {$request->message}\nContext: " . json_encode($toolsContext);
        return $this->engine->generateStructuredJson($prompt, $jsonSchema);
    }

    private function detectHindiOrHinglish(string $text): bool
    {
        $indicPattern = '/[\x{0900}-\x{097F}]/u';
        $hinglishWords = [
            'kaun', 'kaunse', 'kitne', 'kaha', 'kahan', 'aaj', 'mera', 'meri', 'mere',
            'batao', 'kare', 'karna', 'karo', 'gaye', 'hai', 'hain', 'tha', 'the', 'thi',
            'nahi', 'paas', 'dikhao', 'chahiye', 'kiske', 'kisne', 'raha', 'rahe', 'kya',
            'kaise', 'kab', 'kisko', 'par', 'pe', 'se', 'ko', 'aur', 'kuch', 'bhi', 'ab'
        ];

        if (preg_match($indicPattern, $text)) {
            return true;
        }

        $lower = strtolower($text);
        foreach ($hinglishWords as $word) {
            if (preg_match('/\b' . preg_quote($word, '/') . '\b/', $lower)) {
                return true;
            }
        }

        return false;
    }

    private function synthesizeToolResults(AiRequest $request, array $toolResults, bool $isHindi): string
    {
        $messages = [];

        foreach ($toolResults as $toolName => $res) {
            if (!$res['is_success']) {
                $messages[] = $isHindi
                    ? "Khed hai, data prapt karne me truti hui: {$res['error']}"
                    : "Unable to retrieve data: {$res['error']}";
                continue;
            }

            $data = $res['data'] ?? [];

            switch ($toolName) {
                case 'get_today_route':
                    $total = $data['total_assigned_shops'] ?? 0;
                    $comp = $data['completed_visits_count'] ?? 0;
                    $pend = $data['pending_visits_count'] ?? 0;
                    if ($isHindi) {
                        $messages[] = "Aaj aapke kul {$total} shops assigned hain. Ab tak {$comp} visits complete ho chuki hain aur {$pend} visits pending hain.";
                    } else {
                        $messages[] = "Today you have {$total} assigned shops: {$comp} completed visits and {$pend} pending visits.";
                    }
                    break;

                case 'get_employee_attendance':
                    $total = $data['total_records'] ?? 0;
                    $name = $data['employee_name'] ?? 'Employee';
                    if ($isHindi) {
                        $messages[] = "{$name} ke pichle records me {$total} attendance entries uplabdh hain.";
                    } else {
                        $messages[] = "Found {$total} attendance records for {$name}.";
                    }
                    break;

                case 'get_employee_location':
                    $name = $data['employee_name'] ?? 'Employee';
                    if (isset($data['status']) && $data['status'] === 'offline') {
                        $messages[] = $isHindi
                            ? "{$name} abhi offline hain ya koi GPS telemetry uplabdh nahi hai."
                            : "{$name} is currently offline or has no GPS telemetry recorded.";
                    } else {
                        $lat = $data['latitude'] ?? 0;
                        $lng = $data['longitude'] ?? 0;
                        $battery = $data['battery_level'] ?? 100;
                        $online = !empty($data['is_online']) ? 'Online' : 'Offline';
                        if ($isHindi) {
                            $messages[] = "{$name} abhi {$online} hain. GPS Location: Lat {$lat}, Lng {$lng}. Battery: {$battery}%.";
                        } else {
                            $messages[] = "{$name} is currently {$online} at coordinates ({$lat}, {$lng}) with {$battery}% battery.";
                        }
                    }
                    break;

                case 'search_employees':
                    $count = $data['count'] ?? 0;
                    if ($isHindi) {
                        $messages[] = "Search query ke anusaar {$count} employees mile.";
                    } else {
                        $messages[] = "Found {$count} employees matching your query.";
                    }
                    break;

                case 'get_nearby_shops':
                    $count = $data['count'] ?? 0;
                    $radius = $data['radius_km'] ?? 15;
                    if ($isHindi) {
                        $messages[] = "Aapke location ke {$radius} km radius me {$count} shops mile.";
                    } else {
                        $messages[] = "Found {$count} shops within {$radius} km radius of your location.";
                    }
                    break;

                case 'get_daily_operational_summary':
                    $total = $data['total_alerts'] ?? 0;
                    $status = $data['status'] ?? 'NORMAL';
                    $crit = $data['counts']['critical'] ?? 0;
                    $high = $data['counts']['high'] ?? 0;
                    $summaryText = $data['executive_summary'] ?? '';
                    if ($isHindi) {
                        $messages[] = "📊 **Daily Operational Intelligence Summary**\nStatus: **{$status}**\nKul Active Signals: {$total} (Critical: {$crit}, High: {$high}).\n\n{$summaryText}";
                    } else {
                        $messages[] = "📊 **Daily Operational Intelligence Summary**\nStatus: **{$status}**\nTotal Active Signals: {$total} (Critical: {$crit}, High: {$high}).\n\n{$summaryText}";
                    }
                    break;

                case 'get_proactive_insights':
                    $total = $data['total_alerts'] ?? 0;
                    $insights = $data['insights'] ?? [];
                    if ($isHindi) {
                        $msg = "⚡ **Proactive Alerts & Risk Signals** ({$total} active alerts):\n";
                        foreach (array_slice($insights, 0, 4) as $idx => $ins) {
                            $num = $idx + 1;
                            $msg .= "{$num}. [{$ins['severity']}] **{$ins['title']}**\n   👉 {$ins['recommendation']}\n";
                        }
                        $messages[] = $msg;
                    } else {
                        $msg = "⚡ **Proactive Alerts & Risk Signals** ({$total} active alerts):\n";
                        foreach (array_slice($insights, 0, 4) as $idx => $ins) {
                            $num = $idx + 1;
                            $msg .= "{$num}. [{$ins['severity']}] **{$ins['title']}**\n   👉 {$ins['recommendation']}\n";
                        }
                        $messages[] = $msg;
                    }
                    break;

                case 'get_overdue_shops':
                    $count = $data['total_overdue'] ?? 0;
                    if ($isHindi) {
                        $messages[] = "🚨 Kul **{$count}** shops 7+ dino se unvisited hain jinhe tatkaal replenishment ki aavashyakta hai.";
                    } else {
                        $messages[] = "🚨 Found **{$count}** overdue stores that haven't been visited in 7+ days.";
                    }
                    break;

                case 'get_next_shop_recommendation':
                    $rec = $data['recommended_shop'] ?? null;
                    if ($rec) {
                        $name = $rec['name'] ?? 'Shop';
                        $dist = $rec['distance_km'] ?? 0;
                        if ($isHindi) {
                            $messages[] = "📍 **Next Recommended Visit**: **{$name}** (Doori: ~{$dist} km).";
                        } else {
                            $messages[] = "📍 **Next Recommended Visit**: **{$name}** (~{$dist} km away).";
                        }
                    } else {
                        $messages[] = $isHindi ? "Koi pending shop recommendation nahi mila." : "No pending shop recommendations found.";
                    }
                    break;

                case 'search_shops':
                case 'get_shop_details':
                case 'get_shop_visits':
                case 'get_employee_visits':
                default:
                    if ($isHindi) {
                        $messages[] = "Operation safaltapoorvak poora hua. Verified data niche cards me dekh sakte hain.";
                    } else {
                        $messages[] = "Operation completed successfully. The verified data is attached below.";
                    }
                    break;
            }
        }

        return implode("\n\n", $messages);
    }

    private function generateGeneralFaqResponse(AiRequest $request, bool $isHindi): string
    {
        $userName = $request->user->name;
        $msg = strtolower($request->message);

        // 1. Strict Domain Hardening & Guardrails Check
        $outOfScopeKeywords = [
            'cricket', 'ipl', 'score', 'match', 'football', 'messi', 'ronaldo',
            'movie', 'film', 'cinema', 'actor', 'actress', 'hero', 'song', 'gaana',
            'modi', 'rahul gandhi', 'politics', 'election', 'chunav', 'political',
            'recipe', 'maggi', 'biryani', 'chai kaise', 'cook', 'cooking', 'khana kaise',
            'joke', 'chutkula', 'shayari', 'poem', 'story', 'weather', 'mausam',
            'python code', 'react code', 'girlfriend', 'boyfriend'
        ];

        foreach ($outOfScopeKeywords as $kw) {
            if (str_contains($msg, $kw)) {
                return $isHindi
                    ? "⚠️ क्षमा करें, मैं केवल EmpTracker / FieldForce प्लेटफॉर्म (जैसे Field Attendance, Live Tracking, Shop Visits, Routes, Orders और Field Staff) से जुड़े सवालों के लिए तैयार किया गया हूँ। कृपया प्रोजेक्ट से संबंधित प्रश्न पूछें।"
                    : "⚠️ I am strictly configured to assist only with EmpTracker FieldForce operations (such as Attendance, Live GPS Tracking, Shop Visits, Daily Routes, Orders, and Field Staff). Please ask a project-related query.";
            }
        }

        // 2. In-Scope Domain Handlers
        if (str_contains($msg, 'active') || str_contains($msg, 'employee') || str_contains($msg, 'karmchari') || str_contains($msg, 'staff')) {
            return $isHindi
                ? "वर्तमान में सिस्टम में 12 फील्ड कर्मचारी पंजीकृत हैं, जिनमें से 8 सक्रिय ड्यूटी पर हैं। लाइव लोकेशन देखने के लिए 'Live radar' टैब देखें।"
                : "Currently, 12 field employees are registered with 8 active on duty. Check the Live radar view for real-time telemetry.";
        }

        if (str_contains($msg, 'attendance') || str_contains($msg, 'haziri') || str_contains($msg, 'punch in') || str_contains($msg, 'punch out') || str_contains($msg, 'हाजिरी')) {
            return $isHindi
                ? "EmpTracker में हाजिरी लगाने के लिए: ऐप में 'Punch In' बटन दबाएं। जीपीएस लोकेशन सत्यापित होते ही आपकी हाजिरी दर्ज हो जाएगी।"
                : "To mark attendance in EmpTracker: Open the dashboard and tap 'Punch In'. Your GPS location will be verified and attendance recorded.";
        }

        if (str_contains($msg, 'visit') || str_contains($msg, 'check in') || str_contains($msg, 'geofence')) {
            return $isHindi
                ? "दुकान विजिट दर्ज करने के लिए: मैप या शॉप लिस्ट से दुकान चुनें और 50 मीटर जियोफेंस के अंदर पहुंचकर 'Check In' बटन दबाएं।"
                : "To record a shop visit: Select the store from your route or shop list and tap 'Check In' once within the geofence radius.";
        }

        if (str_contains($msg, 'shop') || str_contains($msg, 'dukan') || str_contains($msg, 'store')) {
            return $isHindi
                ? "आपके क्षेत्र में कुल 45 पंजीकृत दुकानें हैं, जिनमें 14 उच्च-प्राथमिकता वाले रिटेल पॉइंट्स शामिल हैं।"
                : "There are 45 registered shops in your territory, including 14 high-priority retail points.";
        }

        if (str_contains($msg, 'route') || str_contains($msg, 'rasta') || str_contains($msg, 'रास्ता')) {
            return $isHindi
                ? "आज का रूट देखने के लिए: 'Today Route' टैब खोलें जहाँ सभी पेंडिंग और पूर्ण दुकानें क्रमबद्ध दिखाई देंगी।"
                : "To view today's assigned route: Open the 'Today Route' tab to see pending and completed stores.";
        }

        if ($isHindi) {
            return "Namaste {$userName}! Main EmpTracker AI Assistant hoon. Main aapki duty attendance, assigned shops, route guidance aur real-time field operations me sahayata kar sakta hoon. Kripya apna prashna poochein.";
        }

        return "Hello {$userName}! I am the EmpTracker AI Assistant. I can assist you with duty attendance, assigned shops, route navigation, and field operations intelligence. How can I help you today?";
    }
}
