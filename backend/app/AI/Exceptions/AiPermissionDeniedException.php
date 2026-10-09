<?php

namespace App\AI\Exceptions;

class AiPermissionDeniedException extends AiException
{
    public function __construct(string $message = "You do not have permission to execute this AI operation or view this resource")
    {
        parent::__construct($message, 403);
    }
}
