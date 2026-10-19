<?php

namespace App\Http\Middleware;

use App\Enums\DeviceStatus;
use App\Exceptions\AccountBlockedException;
use App\Exceptions\DevicePendingException;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureBoundDevice
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user->blocked_at !== null) {
            throw new AccountBlockedException;
        }

        $active = $user->devices()->where('status', DeviceStatus::Active)->first();

        if (! $active || $active->device_uuid !== $request->header('X-Device-Id')) {
            throw new DevicePendingException;
        }

        return $next($request);
    }
}
