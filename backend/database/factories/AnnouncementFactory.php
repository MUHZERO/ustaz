<?php

namespace Database\Factories;

use App\Models\Announcement;
use App\Models\Level;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Announcement>
 */
class AnnouncementFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'level_id' => Level::factory(),
            'title' => fake()->sentence(4),
            'body' => fake()->paragraph(),
            'image_path' => null,
            'published_at' => now(),
        ];
    }
}
