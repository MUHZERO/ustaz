<?php

namespace App\Exceptions;

final class ExamNotOpenException extends ApiException
{
    public function status(): int
    {
        return 409;
    }

    public function errorCode(): string
    {
        return 'exam_not_open';
    }
}
