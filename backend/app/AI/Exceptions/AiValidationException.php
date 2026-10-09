<?php

namespace App\AI\Exceptions;

class AiValidationException extends AiException
{
    protected array $errors;

    public function __construct(string $message = "AI request validation failed", array $errors = [])
    {
        $this->errors = $errors;
        parent::__construct($message, 422);
    }

    public function getErrors(): array
    {
        return $this->errors;
    }
}
