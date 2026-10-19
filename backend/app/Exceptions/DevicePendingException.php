<?php

namespace App\Exceptions;

class DevicePendingException extends ApiException
{
    public function status(): int
    {
        return 403;
    }

    public function errorCode(): string
    {
        return 'device_pending';
    }
}
