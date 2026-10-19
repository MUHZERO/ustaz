<?php

namespace Database\Factories;

use App\Enums\AssessmentKind;
use App\Enums\ShowAnswers;
use App\Models\Assessment;
use App\Models\Category;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Assessment>
 */
class AssessmentFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'kind' => AssessmentKind::Quiz,
            'title' => fake()->sentence(3),
            'category_id' => Category::factory(),
            'lecture_id' => null,
            'opens_at' => null,
            'closes_at' => null,
            'duration_minutes' => null,
            'max_attempts' => null,
            'shuffle' => false,
            'show_answers' => ShowAnswers::AfterSubmit,
            'is_free' => false,
        ];
    }
}
