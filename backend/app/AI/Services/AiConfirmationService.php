<?php

namespace App\AI\Services;

use App\AI\Contracts\AiToolInterface;
use App\AI\Exceptions\AiValidationException;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class AiConfirmationService
{
    private const TOKEN_PREFIX = 'ai_action_conf_';
    private const TTL_MINUTES = 10;

    /**
     * Create a cryptographic, tamper-proof, short-lived confirmation proposal
     */
    public function createProposal(User $user, AiToolInterface $tool, array $parameters, string $summary, string $impact = ''): array
    {
        $tokenId = Str::uuid()->toString();
        $expiresAt = Carbon::now()->addMinutes(self::TTL_MINUTES)->toIso8601String();

        $payload = [
            'token' => $tokenId,
            'user_id' => $user->id,
            'user_role' => $user->role,
            'action' => $tool->getName(),
            'parameters' => $parameters,
            'summary' => $summary,
            'impact' => $impact ?: 'This action will update database records within your authorized access scope.',
            'created_at' => Carbon::now()->toIso8601String(),
            'expires_at' => $expiresAt,
            'status' => 'PENDING',
        ];

        // Generate HMAC signature to prevent parameter tampering
        $signature = $this->generateSignature($payload);
        $payload['signature'] = $signature;

        // Store in cache with expiration
        Cache::put(self::TOKEN_PREFIX . $tokenId, $payload, now()->addMinutes(self::TTL_MINUTES));

        return [
            'confirmation_token' => $tokenId,
            'action' => $tool->getName(),
            'summary' => $summary,
            'impact' => $payload['impact'],
            'parameters' => $parameters,
            'expires_at' => $expiresAt,
            'requires_confirmation' => true,
        ];
    }

    /**
     * Verify and retrieve a confirmation token payload
     *
     * @throws AiValidationException
     */
    public function verifyToken(string $tokenId, User $user): array
    {
        $cached = Cache::get(self::TOKEN_PREFIX . $tokenId);

        if (!$cached) {
            throw new AiValidationException("Confirmation token has expired or is invalid. Please request the action again.");
        }

        // Verify status
        if (($cached['status'] ?? '') !== 'PENDING') {
            throw new AiValidationException("This action has already been processed or cancelled (Idempotency protected).");
        }

        // Verify user ownership
        if ((int)$cached['user_id'] !== (int)$user->id) {
            throw new \App\AI\Exceptions\AiPermissionDeniedException("Unauthorized: This action proposal was generated for another user.");
        }

        // Verify expiration
        if (Carbon::parse($cached['expires_at'])->isPast()) {
            Cache::forget(self::TOKEN_PREFIX . $tokenId);
            throw new AiValidationException("Confirmation token has expired. Please repeat the command.");
        }

        // Verify HMAC signature
        $storedSignature = $cached['signature'] ?? '';
        $tempPayload = $cached;
        unset($tempPayload['signature']);

        if (!hash_equals($this->generateSignature($tempPayload), $storedSignature)) {
            throw new AiValidationException("Security validation failed: Confirmation payload integrity check failed.");
        }

        return $cached;
    }

    /**
     * Mark token as consumed/confirmed (Idempotency protection)
     */
    public function consumeToken(string $tokenId): void
    {
        $cached = Cache::get(self::TOKEN_PREFIX . $tokenId);
        if ($cached) {
            $cached['status'] = 'CONFIRMED';
            $cached['consumed_at'] = Carbon::now()->toIso8601String();
            // Keep briefly as tombstone for idempotency rejection
            Cache::put(self::TOKEN_PREFIX . $tokenId, $cached, now()->addMinutes(10));
        }
    }

    /**
     * Cancel an action proposal
     */
    public function cancelToken(string $tokenId, User $user): bool
    {
        $cached = Cache::get(self::TOKEN_PREFIX . $tokenId);
        if (!$cached || (int)$cached['user_id'] !== (int)$user->id) {
            return false;
        }

        $cached['status'] = 'CANCELLED';
        Cache::put(self::TOKEN_PREFIX . $tokenId, $cached, now()->addMinutes(5));
        return true;
    }

    private function generateSignature(array $payload): string
    {
        $secret = config('app.key') ?: 'fieldforce_secure_fallback_key';
        $serialized = json_encode([
            'token' => $payload['token'] ?? '',
            'user_id' => $payload['user_id'] ?? '',
            'action' => $payload['action'] ?? '',
            'parameters' => $payload['parameters'] ?? [],
            'expires_at' => $payload['expires_at'] ?? '',
        ]);

        return hash_hmac('sha256', $serialized, $secret);
    }
}
