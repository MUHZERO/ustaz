<?php

namespace App\Enums;

enum DeviceStatus: string
{
    case Active = 'active';
    case Pending = 'pending';
    case Revoked = 'revoked';
}
