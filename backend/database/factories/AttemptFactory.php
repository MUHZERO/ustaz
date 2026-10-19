<?php

namespace Database\Factories;

use App\Enums\AttemptStatus;
use App\Models\Assessment;
use App\Models\Attempt;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Attempt>
 */
class AttemptFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'assessment_id' => Assessment::factory(),
            'status' => AttemptStatus::InProgress,
            'started_at' => now(),
            'deadline_at' => null,
            'submitted_at' => null,
            'score' => null,
            'max_score' => null,
        ];
    }
}
