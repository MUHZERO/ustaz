<?php

namespace Database\Factories;

use App\Models\Category;
use App\Models\Level;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Category>
 */
class CategoryFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'level_id' => Level::factory(),
            'name' => fake()->unique()->words(2, true),
            'position' => fake()->numberBetween(0, 9),
            'is_free' => false,
        ];
    }
}
