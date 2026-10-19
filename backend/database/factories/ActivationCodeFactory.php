<?php

namespace Database\Factories;

use App\Models\ActivationCode;
use App\Models\Category;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ActivationCode>
 */
class ActivationCodeFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'code' => $this->generateCode(),
            'category_id' => Category::factory(),
            'batch_id' => fake()->uuid(),
            'ends_at' => null,
            'expires_at' => null,
            'max_uses' => 1,
            'uses_count' => 0,
        ];
    }

    protected function generateCode(): string
    {
        $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        $code = '';

        for ($i = 0; $i < 10; $i++) {
            $code .= $alphabet[random_int(0, strlen($alphabet) - 1)];
        }

        return $code;
    }
}
