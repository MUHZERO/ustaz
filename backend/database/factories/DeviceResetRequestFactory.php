<?php

namespace Database\Factories;

use App\Enums\ReviewStatus;
use App\Models\DeviceResetRequest;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<DeviceResetRequest>
 */
class DeviceResetRequestFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'device_uuid' => fake()->uuid(),
            'status' => ReviewStatus::Pending,
            'handled_by' => null,
        ];
    }
}
