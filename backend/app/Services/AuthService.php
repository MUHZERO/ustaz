<?php

namespace App\Services;

use App\Enums\DeviceStatus;
use App\Enums\UserRole;
use App\Exceptions\AccountBlockedException;
use App\Exceptions\DevicePendingException;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthService
{
    public function __construct(private DeviceService $devices) {}

    /**
     * @param  array<string, mixed>  $data
     * @return array{token: string, user: User}
     */
    public function register(array $data): array
    {
        $user = User::create([
            'name' => $data['name'],
            'phone' => $data['phone'],
            'parent_phone' => $data['parent_phone'] ?? null,
            'password' => $data['password'],
            'role' => UserRole::Student,
            'level_id' => $data['level_id'],
        ]);

        $device = $this->devices->bind($user, $data['device_id']);

        return [
            'token' => $user->createToken($device->device_uuid)->plainTextToken,
            'user' => $user->load('level'),
        ];
    }

    /**
     * @return array{token: string, user: User}
     */
    public function login(string $phone, string $password, string $uuid): array
    {
        $user = User::where('phone', $phone)->first();

        if (! $user || ! Hash::check($password, $user->password)) {
            throw ValidationException::withMessages(['phone' => __('auth.failed')]);
        }

        if ($user->blocked_at !== null) {
            throw new AccountBlockedException;
        }

        $device = $this->devices->bind($user, $uuid);

        if ($device->status === DeviceStatus::Pending) {
            throw new DevicePendingException;
        }

        $user->tokens()->where('name', $uuid)->delete();

        return [
            'token' => $user->createToken($uuid)->plainTextToken,
            'user' => $user->load('level'),
        ];
    }
}
