<?php

namespace App\Exceptions;

final class CodeUsedUpException extends ApiException
{
    public function status(): int
    {
        return 422;
    }

    public function errorCode(): string
    {
        return 'code_used_up';
    }
}
