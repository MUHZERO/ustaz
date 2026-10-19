<?php

namespace Database\Factories;

use App\Models\Segment;
use App\Models\User;
use App\Models\WatchProgress;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<WatchProgress>
 */
class WatchProgressFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'segment_id' => Segment::factory(),
            'last_position_seconds' => 0,
            'watched_seconds' => 0,
            'completed_at' => null,
        ];
    }
}
