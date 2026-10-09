<?php

namespace App\AI\Exceptions;

class AiDisabledException extends AiException
{
    public function __construct(string $message = "AI features are currently disabled in configuration")
    {
        parent::__construct($message, 503);
    }
}
