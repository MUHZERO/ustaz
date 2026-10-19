<?php

namespace App\Enums;

enum ShowAnswers: string
{
    case AfterSubmit = 'after_submit';
    case AfterClose = 'after_close';
}
