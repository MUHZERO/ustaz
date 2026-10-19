<?php

namespace App\Exceptions;

final class AlreadySubmittedException extends ApiException
{
    public function status(): int
    {
        return 409;
    }

    public function errorCode(): string
    {
        return 'already_submitted';
    }
}
