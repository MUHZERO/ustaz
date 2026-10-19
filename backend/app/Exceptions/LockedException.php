<?php

namespace App\Exceptions;

class LockedException extends ApiException
{
    public function status(): int
    {
        return 403;
    }

    public function errorCode(): string
    {
        return 'locked';
    }
}
