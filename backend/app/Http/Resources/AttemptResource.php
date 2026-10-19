<?php

namespace App\Http\Resources;

use App\Models\Attempt;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A running attempt. Never exposes correct answers: the snapshot's
 * correct_option_id and the answers' is_correct stay on the server.
 *
 * @mixin Attempt
 */
class AttemptResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'assessment_id' => $this->assessment_id,
            'kind' => $this->assessment->kind->value,
            'started_at' => $this->started_at->toIso8601String(),
            'deadline_at' => $this->deadline_at?->toIso8601String(),
            'status' => $this->status->value,
            'questions' => $this->answers->map(fn ($answer) => [
                'id' => $answer->question_id,
                'text' => $answer->snapshot['text'] ?? null,
                'image_url' => $answer->snapshot['image_url'] ?? null,
                'options' => $answer->snapshot['options'] ?? [],
            ])->values(),
            'answers' => (object) $this->answers->whereNotNull('chosen_option_id')->pluck('chosen_option_id', 'question_id')->all(),
        ];
    }
}
