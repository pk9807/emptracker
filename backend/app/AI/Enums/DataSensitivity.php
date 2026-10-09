<?php

namespace App\AI\Enums;

enum DataSensitivity: string
{
    case PUBLIC = 'public';
    case INTERNAL = 'internal';
    case SENSITIVE = 'sensitive';
    case HIGHLY_SENSITIVE = 'highly_sensitive';

    public function isCloudAllowed(): bool
    {
        return match ($this) {
            self::PUBLIC, self::INTERNAL => true,
            self::SENSITIVE, self::HIGHLY_SENSITIVE => false,
        };
    }
}
