<?php

namespace App\AI\Enums;

enum UserRole: string
{
    case ADMIN = 'admin';
    case EMPLOYEE = 'employee';

    public static function fromString(?string $role): self
    {
        $normalized = strtolower(trim($role ?? 'employee'));
        return match ($normalized) {
            'admin', 'superadmin', 'manager' => self::ADMIN,
            default => self::EMPLOYEE,
        };
    }
}
