<?php

namespace Database\Factories;

use App\Models\Category;
use App\Models\Paper;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Paper>
 */
class PaperFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'category_id' => Category::factory(),
            'title' => fake()->sentence(3),
            'path' => 'papers/'.fake()->uuid().'.pdf',
        ];
    }
}
