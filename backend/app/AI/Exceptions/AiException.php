<?php

namespace App\AI\Exceptions;

use Exception;

class AiException extends Exception
{
    public function __construct(string $message = "An AI error occurred", int $code = 500, ?\Throwable $previous = null)
    {
        parent::__construct($message, $code, $previous);
    }
}
