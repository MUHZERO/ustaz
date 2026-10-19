<?php

namespace App\Exceptions;

class AccountBlockedException extends ApiException
{
    public function status(): int
    {
        return 403;
    }

    public function errorCode(): string
    {
        return 'account_blocked';
    }
}
