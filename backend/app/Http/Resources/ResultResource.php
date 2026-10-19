<?php

namespace App\Http\Resources;

use App\Models\Attempt;
use App\Services\AttemptService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Attempt */
class ResultResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $max = (float) $this->max_score;

        return [
            'attempt_id' => $this->id,
            'title' => $this->whenLoaded('assessment', fn () => $this->assessment->title),
            'kind' => $this->whenLoaded('assessment', fn () => $this->assessment->kind->value),
            'score' => $this->number($this->score),
            'max_score' => $this->number($this->max_score),
            'percent' => $max > 0 ? round((float) $this->score / $max * 100, 2) : null,
            'passed' => null,
            'submitted_at' => $this->submitted_at?->toIso8601String(),
            'review_available' => app(AttemptService::class)->reviewAvailable($this->resource),
            'review_request' => null,
        ];
    }

    private function number(mixed $value): int|float|null
    {
        if ($value === null) {
            return null;
        }

        $float = (float) $value;

        return floor($float) === $float ? (int) $float : $float;
    }
}
