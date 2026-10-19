<?php

namespace Database\Factories;

use App\Enums\SegmentType;
use App\Models\Lecture;
use App\Models\Segment;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Segment>
 */
class SegmentFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'lecture_id' => Lecture::factory(),
            'type' => SegmentType::Video,
            'position' => fake()->numberBetween(0, 9),
            'title' => fake()->sentence(3),
            'is_gating' => false,
            'youtube_id' => fake()->regexify('[A-Za-z0-9_-]{11}'),
            'duration_seconds' => fake()->numberBetween(60, 3600),
            'pdf_path' => null,
            'assessment_id' => null,
            'pass_percent' => null,
        ];
    }
}
