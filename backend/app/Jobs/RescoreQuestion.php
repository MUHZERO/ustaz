<?php

namespace App\Jobs;

use App\Services\ReviewService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

final class RescoreQuestion implements ShouldQueue
{
    use Queueable;

    public function __construct(public readonly int $questionId, public readonly int $correctOptionId) {}

    public function handle(ReviewService $reviews): void
    {
        $reviews->rescoreQuestion($this->questionId, $this->correctOptionId);
    }
}
