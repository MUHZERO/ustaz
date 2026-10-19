<?php

namespace App\Http\Resources;

use App\Models\AttemptAnswer;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin AttemptAnswer */
class ReviewItemResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'question' => [
                'id' => $this->question_id,
                'text' => $this->snapshot['text'] ?? null,
                'image_url' => $this->snapshot['image_url'] ?? null,
                'options' => $this->snapshot['options'] ?? [],
            ],
            'chosen_option_id' => $this->chosen_option_id,
            'correct_option_id' => $this->snapshot['correct_option_id'] ?? null,
            'is_correct' => (bool) $this->is_correct,
            'explanation' => $this->snapshot['explanation'] ?? null,
        ];
    }
}
