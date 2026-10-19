<?php

namespace App\Exceptions;

final class ReviewAlreadyRequestedException extends ApiException
{
    public function status(): int
    {
        return 409;
    }

    public function errorCode(): string
    {
        return 'review_already_requested';
    }
}
