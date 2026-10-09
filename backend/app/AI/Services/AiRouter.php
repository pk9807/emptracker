<?php

namespace App\AI\Services;

use App\AI\Contracts\AiProviderInterface;
use App\AI\DTOs\AiRequest;
use App\AI\DTOs\AiToolCall;
use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\AI\Providers\CloudAiProvider;
use App\AI\Providers\LocalAiProvider;
use App\Models\User;

class AiRouter
{
    protected ToolRegistry $toolRegistry;
    protected LocalAiProvider $localProvider;
    protected CloudAiProvider $cloudProvider;

    public function __construct(
        ToolRegistry $toolRegistry,
        LocalAiProvider $localProvider,
        CloudAiProvider $cloudProvider
    ) {
        $this->toolRegistry = $toolRegistry;
        $this->localProvider = $localProvider;
        $this->cloudProvider = $cloudProvider;
    }

    /**
     * Classify privacy sensitivity tier based on user request and matched tools
     */
    public function classifyPrivacy(AiRequest $request, array $toolCalls): DataSensitivity
    {
        $highestTier = DataSensitivity::INTERNAL;

        // Check if query directly asks for live GPS or personal location
        $msg = strtolower($request->message);
        if ($this->matchesAny($msg, ['location', 'kahan', 'kaha', 'gps', 'radar', 'live tracking'])) {
            return DataSensitivity::HIGHLY_SENSITIVE;
        }

        foreach ($toolCalls as $call) {
            $tool = $this->toolRegistry->getTool($call->toolName);
            if (!$tool) continue;

            $toolSensitivity = $tool->getDataSensitivity();
            if ($toolSensitivity === DataSensitivity::HIGHLY_SENSITIVE) {
                return DataSensitivity::HIGHLY_SENSITIVE;
            }
            if ($toolSensitivity === DataSensitivity::SENSITIVE) {
                $highestTier = DataSensitivity::SENSITIVE;
            }
        }

        return $highestTier;
    }

    /**
     * Determine which tools should be invoked based on user message and role
     *
     * @param AiRequest $request
     * @return array<AiToolCall>
     */
    public function routeTools(AiRequest $request): array
    {
        $message = strtolower($request->message);
        $role = $request->userRole;
        $calls = [];

        // 1. Attendance Queries ("attendance", "punch", "duty", "hazri", "login time")
        if ($this->matchesAny($message, ['attendance', 'punch', 'duty', 'hazri', 'aaj ki attendance', 'meri attendance', 'punch in', 'check in'])) {
            $calls[] = new AiToolCall('get_employee_attendance', [
                'employee_id' => $request->user->id,
            ]);
        }

        // 2. Today's Route & Assigned Tasks ("route", "assigned shop", "aaj ka route", "pending visit", "tasks", "kaunse shops")
        if ($this->matchesAny($message, ['route', 'assigned', 'task', 'pending', 'shops visit', 'aaj ke shop', 'meri visits', 'schedule', 'kahan jana'])) {
            $calls[] = new AiToolCall('get_today_route', [
                'employee_id' => $request->user->id,
            ]);
        }

        // 3. Employee Location / Radar ("location", "kahan hai", "kaha hai", "radar", "live", "gps")
        if ($this->matchesAny($message, ['kaha hai', 'kahan hai', 'location', 'radar', 'live tracking', 'gps', 'position'])) {
            // If admin queries a specific name or all
            if ($role === UserRole::ADMIN) {
                $matchedUser = $this->findMentionedEmployee($message);
                if ($matchedUser) {
                    $calls[] = new AiToolCall('get_employee_location', [
                        'employee_id' => $matchedUser->id,
                    ]);
                } else {
                    $calls[] = new AiToolCall('search_employees', [
                        'is_active' => true,
                    ]);
                }
            } else {
                $calls[] = new AiToolCall('get_employee_location', [
                    'employee_id' => $request->user->id,
                ]);
            }
        }

        // 4. Nearby Shops ("nearby", "paas me", "paas ke shop", "aas paas", "closest")
        if ($this->matchesAny($message, ['nearby', 'paas', 'aas paas', 'closest', 'near me', 'around me'])) {
            $lat = $request->clientContext['latitude'] ?? 26.4499;
            $lng = $request->clientContext['longitude'] ?? 80.3319;
            $calls[] = new AiToolCall('get_nearby_shops', [
                'latitude' => (float)$lat,
                'longitude' => (float)$lng,
                'radius_km' => 15.0,
            ]);
        }

        // 5. Shop Search ("shop search", "dukan", "store", "find shop")
        if ($this->matchesAny($message, ['shop search', 'dukan', 'find shop', 'dhoondo', 'search shop'])) {
            $calls[] = new AiToolCall('search_shops', [
                'query' => $this->extractKeywords($message),
            ]);
        }

        // --- WRITE ACTIONS (Requires 2-Step Confirmation) ---

        // 7. Assign Shop to Employee (Admin only write action)
        if ($this->matchesAny($message, ['assign shop', 'allot shop', 'shop assign', 'ko assign', 'assign kardo', 'assign karo', 'allot karo'])) {
            $matchedEmp = $this->findMentionedEmployee($message);
            $shopId = $this->findMentionedShopId($message);
            $calls[] = new AiToolCall('assign_employee_shop', [
                'employee_id' => $matchedEmp?->id ?? ($request->userRole === UserRole::ADMIN ? 2 : $request->user->id),
                'shop_id' => $shopId ?: (\App\Models\Shop::first()?->id ?? 13),
            ]);
            return $calls;
        }

        // 8. Add Urgent Shop Note / Remarks (Write action)
        if ($this->matchesAny($message, ['urgent note', 'shop note', 'note add', 'note daalo', 'add note'])) {
            $shopId = $this->findMentionedShopId($message) ?: 1;
            $noteText = $this->extractNoteContent($message);
            $calls[] = new AiToolCall('add_shop_urgent_note', [
                'shop_id' => $shopId,
                'note' => $noteText ?: 'Urgent operational follow-up required.',
            ]);
            return $calls;
        }

        // --- PHASE 5: MAP & LOCATION INTELLIGENCE TOOLS ---

        // 10. Overdue & Unvisited Shops ("7 din", "unvisited", "overdue", "visit nahi hue", "pending shop", "last visit")
        if ($this->matchesAny($message, ['7 din', 'unvisited', 'overdue', 'visit nahi hue', 'last visit', 'din se visit'])) {
            $calls[] = new AiToolCall('get_overdue_shops', [
                'days' => 7,
                'employee_id' => $role === UserRole::ADMIN ? null : $request->user->id,
            ]);
            return $calls;
        }

        // 11. Next Shop Recommendation ("next shop", "agla shop", "pehle visit", "recommend shop", "kaunsa shop pehle")
        if ($this->matchesAny($message, ['next shop', 'agla shop', 'pehle visit', 'recommend', 'next visit', 'sabse pehle'])) {
            $lat = $request->clientContext['latitude'] ?? null;
            $lng = $request->clientContext['longitude'] ?? null;
            $calls[] = new AiToolCall('get_next_shop_recommendation', [
                'employee_id' => $request->user->id,
                'latitude' => $lat,
                'longitude' => $lng,
            ]);
            return $calls;
        }

        // 12. Full Route Telemetry Summary ("route summarize", "route summary", "kitne km", "distance travel", "trajectory", "unusual activity")
        if ($this->matchesAny($message, ['route summarize', 'route summary', 'summarize karo', 'kitne km', 'trajectory', 'unusual activity', 'idle'])) {
            $targetEmp = $role === UserRole::ADMIN ? ($this->findMentionedEmployee($message) ?? $request->user) : $request->user;
            $calls[] = new AiToolCall('get_employee_route_summary', [
                'employee_id' => $targetEmp->id,
            ]);
            return $calls;
        }

        // 13. Area Coverage Summary ("coverage", "area summary", "coverage kitni", "city coverage")
        if ($role === UserRole::ADMIN && $this->matchesAny($message, ['coverage', 'area summary', 'city coverage', 'region'])) {
            $lat = $request->clientContext['latitude'] ?? 26.4499;
            $lng = $request->clientContext['longitude'] ?? 80.3319;
            $calls[] = new AiToolCall('get_area_coverage_summary', [
                'latitude' => (float)$lat,
                'longitude' => (float)$lng,
                'radius_km' => 15.0,
            ]);
            return $calls;
        }

        // --- PHASE 7: PROACTIVE INTELLIGENCE & MANAGEMENT ALERTS ---

        // 14. Executive Daily Operational Summary (Admin only)
        if ($role === UserRole::ADMIN && $this->matchesAny($message, ['daily summary', 'operational summary', 'aaj ka summary', 'executive summary', 'operations status', 'kaisa chal raha hai', 'overall status'])) {
            $calls[] = new AiToolCall('get_daily_operational_summary', []);
            return $calls;
        }

        // 15. Proactive Alerts & Risks
        if ($this->matchesAny($message, ['alert', 'alerts', 'kya alerts', 'kya risk', 'risks', 'insights', 'proactive', 'kuch alert hai', 'anomalies', 'warnings', 'khatre', 'dhyan'])) {
            $calls[] = new AiToolCall('get_proactive_insights', [
                'severity_filter' => 'ALL',
            ]);
            return $calls;
        }

        return $calls;
    }

    private function findMentionedShopId(string $text): ?int
    {
        if (preg_match('/shop\s*#?(\d+)/i', $text, $matches)) {
            return (int)$matches[1];
        }
        if (preg_match('/id\s*#?(\d+)/i', $text, $matches)) {
            return (int)$matches[1];
        }
        // Match existing shop names in DB
        $shops = \App\Models\Shop::take(20)->get(['id', 'name']);
        foreach ($shops as $shop) {
            $shopFirstName = strtolower(explode(' ', $shop->name)[0]);
            if (strlen($shopFirstName) > 2 && str_contains($text, $shopFirstName)) {
                return (int)$shop->id;
            }
        }
        return null;
    }

    private function extractNoteContent(string $text): string
    {
        if (str_contains($text, ':')) {
            $parts = explode(':', $text, 2);
            return trim($parts[1]);
        }
        return trim($text);
    }

    /**
     * Select the best inference provider following LOCAL-FIRST priority and Privacy Gate
     */
    public function selectProvider(AiRequest $request, DataSensitivity $privacy, bool $forceCloud = false): AiProviderInterface
    {
        // 1. Local AI is always preferred first
        if (!$forceCloud && $this->localProvider->isAvailable()) {
            return $this->localProvider;
        }

        // 2. Cloud AI fallback: ONLY if privacy classification permits
        if ($this->cloudProvider->isAvailable() && $privacy->isCloudAllowed()) {
            return $this->cloudProvider;
        }

        // Fallback to local
        return $this->localProvider;
    }

    public function determineFallbackReason(AiRequest $request, DataSensitivity $privacy, bool $forceCloud = false): \App\AI\Enums\FallbackReason
    {
        if (!$forceCloud && $this->localProvider->isAvailable()) {
            return \App\AI\Enums\FallbackReason::NONE;
        }

        if (!$this->localProvider->isAvailable()) {
            return \App\AI\Enums\FallbackReason::LOCAL_MODEL_UNAVAILABLE;
        }

        if ($forceCloud) {
            return $privacy->isCloudAllowed() 
                ? \App\AI\Enums\FallbackReason::USER_POLICY_ALLOWED 
                : \App\AI\Enums\FallbackReason::LOCAL_MODEL_UNSUPPORTED;
        }

        return \App\AI\Enums\FallbackReason::NONE;
    }

    public function getRoutingDecisionLog(AiRequest $request, DataSensitivity $privacy, string $selectedProvider, bool $forceCloud = false): array
    {
        $fallbackReason = $this->determineFallbackReason($request, $privacy, $forceCloud);

        return [
            'privacy_tier' => $privacy->value,
            'cloud_transmission_allowed' => $privacy->isCloudAllowed(),
            'selected_provider' => $selectedProvider,
            'fallback_reason' => $fallbackReason->value,
            'local_available' => $this->localProvider->isAvailable(),
            'cloud_available' => $this->cloudProvider->isAvailable(),
        ];
    }

    private function matchesAny(string $text, array $patterns): bool
    {
        foreach ($patterns as $pattern) {
            if (str_contains($text, strtolower($pattern))) {
                return true;
            }
        }
        return false;
    }

    private function findMentionedEmployee(string $text): ?User
    {
        $employees = User::where('role', 'employee')->get(['id', 'name']);
        foreach ($employees as $emp) {
            $firstName = strtolower(explode(' ', $emp->name)[0]);
            if (str_contains($text, $firstName)) {
                return $emp;
            }
        }
        return null;
    }

    private function extractKeywords(string $text): string
    {
        $stopWords = ['find', 'search', 'show', 'batao', 'dikhao', 'kare', 'shop', 'employee', 'me', 'the', 'is', 'a', 'ko', 'se'];
        $words = explode(' ', $text);
        $filtered = array_filter($words, fn($w) => !in_array($w, $stopWords) && strlen($w) > 2);
        return implode(' ', $filtered);
    }
}
