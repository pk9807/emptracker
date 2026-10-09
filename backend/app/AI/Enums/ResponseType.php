<?php

namespace App\AI\Enums;

enum ResponseType: string
{
    case ANSWER = 'answer';
    case ACTION_CONFIRMATION = 'action_confirmation';
    case CLARIFICATION = 'clarification';
    case ERROR = 'error';
}
