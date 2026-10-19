<?php

namespace Database\Factories;

use App\Models\Level;
use App\Models\Question;
use App\Models\QuestionOption;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Database\Eloquent\Factories\Sequence;

/**
 * @extends Factory<Question>
 */
class QuestionFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'text' => fake()->sentence().'?',
            'image_path' => null,
            'explanation' => fake()->sentence(),
            'difficulty' => fake()->numberBetween(1, 3),
            'level_id' => Level::factory(),
            'archived_at' => null,
        ];
    }

    public function withOptions(int $count = 4): static
    {
        return $this->afterCreating(function (Question $question) use ($count) {
            QuestionOption::factory()
                ->count($count)
                ->for($question)
                ->sequence(fn (Sequence $sequence) => ['is_correct' => $sequence->index === 0])
                ->create();
        });
    }
}
