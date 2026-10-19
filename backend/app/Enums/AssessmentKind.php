<?php

namespace App\Enums;

enum AssessmentKind: string
{
    case Quiz = 'quiz';
    case Homework = 'homework';
    case Exam = 'exam';
}
