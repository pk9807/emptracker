<?php

namespace App\AI\DTOs;

use App\AI\Enums\DataSensitivity;
use App\AI\Enums\UserRole;
use App\Models\User;

class AiRequest
{
    public function __construct(
        public readonly User $user,
        public readonly string $message,
        public readonly UserRole $userRole,
        public readonly ?string $conversationId = null,
        public readonly array $history = [],
        public readonly array $clientContext = [],
        public readonly bool $localOnly = false,
        public readonly DataSensitivity $privacyClassification = DataSensitivity::INTERNAL
    ) {}

    public static function create(
        User $user,
        string $message,
        ?string $conversationId = null,
        array $history = [],
        array $clientContext = [],
        bool $localOnly = false
    ): self {
        return new self(
            user: $user,
            message: trim($message),
            userRole: UserRole::fromString($user->role),
            conversationId: $conversationId,
            history: $history,
            clientContext: $clientContext,
            localOnly: $localOnly,
            privacyClassification: DataSensitivity::INTERNAL
        );
    }
}
