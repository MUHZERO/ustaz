<?php

namespace App\Enums;

enum SegmentType: string
{
    case Video = 'video';
    case Pdf = 'pdf';
    case Quiz = 'quiz';
}
