<?php

namespace App\Exceptions;

final class CodeInvalidException extends ApiException
{
    public function status(): int
    {
        return 422;
    }

    public function errorCode(): string
    {
        return 'code_invalid';
    }
}
