<?php

namespace App\Services;

use App\Enums\DeviceStatus;
use App\Enums\ReviewStatus;
use App\Models\Device;
use App\Models\DeviceResetRequest;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class DeviceService
{
    /**
     * Bind a device uuid for the user, creating a reset request when another
     * device is already active.
     */
    public function bind(User $user, string $uuid): Device
    {
        $active = $user->devices()->where('status', DeviceStatus::Active)->first();

        if (! $active) {
            return $user->devices()->create([
                'device_uuid' => $uuid,
                'status' => DeviceStatus::Active,
                'last_seen_at' => now(),
            ]);
        }

        if ($active->device_uuid === $uuid) {
            $active->touch('last_seen_at');

            return $active;
        }

        $pending = $user->devices()
            ->where('device_uuid', $uuid)
            ->where('status', DeviceStatus::Pending)
            ->first();

        if (! $pending) {
            $pending = $user->devices()->create([
                'device_uuid' => $uuid,
                'status' => DeviceStatus::Pending,
                'last_seen_at' => now(),
            ]);
        }

        $user->deviceResetRequests()->firstOrCreate([
            'device_uuid' => $uuid,
            'status' => ReviewStatus::Pending,
        ]);

        return $pending;
    }

    /**
     * Approve a pending reset: revoke the current device and its tokens and
     * activate the requested one.
     */
    public function approve(DeviceResetRequest $request, User $by): void
    {
        DB::transaction(function () use ($request, $by) {
            $user = $request->user()->firstOrFail();

            $user->devices()->where('status', DeviceStatus::Active)->update([
                'status' => DeviceStatus::Revoked,
            ]);

            $user->tokens()->delete();

            $user->devices()
                ->where('device_uuid', $request->device_uuid)
                ->where('status', DeviceStatus::Pending)
                ->update(['status' => DeviceStatus::Active, 'last_seen_at' => now()]);

            $request->update([
                'status' => ReviewStatus::Accepted,
                'handled_by' => $by->id,
            ]);
        });
    }
}
