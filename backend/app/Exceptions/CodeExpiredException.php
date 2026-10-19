<?php

namespace App\Exceptions;

final class CodeExpiredException extends ApiException
{
    public function status(): int
    {
        return 422;
    }

    public function errorCode(): string
    {
        return 'code_expired';
    }
}
