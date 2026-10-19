<?php

namespace Database\Factories;

use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\Question;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<AttemptAnswer>
 */
class AttemptAnswerFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'attempt_id' => Attempt::factory(),
            'question_id' => Question::factory(),
            'snapshot' => [
                'text' => fake()->sentence(),
                'image_path' => null,
                'options' => [],
                'correct_option_id' => null,
                'mark' => 1,
            ],
            'chosen_option_id' => null,
            'is_correct' => null,
        ];
    }
}
