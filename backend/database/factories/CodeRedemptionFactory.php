<?php

namespace Database\Factories;

use App\Models\ActivationCode;
use App\Models\CodeRedemption;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CodeRedemption>
 */
class CodeRedemptionFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'activation_code_id' => ActivationCode::factory(),
            'user_id' => User::factory(),
            'created_at' => now(),
        ];
    }
}
