<?php

namespace Database\Factories;

use App\Models\Attempt;
use App\Models\ScoreHistory;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ScoreHistory>
 */
class ScoreHistoryFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'attempt_id' => Attempt::factory(),
            'old_score' => 0,
            'new_score' => fake()->randomFloat(2, 0, 20),
            'reason' => 'rescore',
        ];
    }
}
