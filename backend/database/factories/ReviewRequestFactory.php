<?php

namespace Database\Factories;

use App\Enums\ReviewStatus;
use App\Models\Attempt;
use App\Models\ReviewRequest;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ReviewRequest>
 */
class ReviewRequestFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'attempt_id' => Attempt::factory(),
            'note' => fake()->sentence(),
            'status' => ReviewStatus::Pending,
            'reply' => null,
            'handled_by' => null,
        ];
    }
}
