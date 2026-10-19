<?php

namespace Database\Factories;

use App\Models\Category;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Subscription>
 */
class SubscriptionFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'category_id' => Category::factory(),
            'starts_at' => now(),
            'ends_at' => now()->addMonth(),
            'granted_by' => null,
            'code_redemption_id' => null,
        ];
    }
}
