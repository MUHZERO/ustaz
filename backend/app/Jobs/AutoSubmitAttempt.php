<?php

namespace App\Jobs;

use App\Models\Attempt;
use App\Services\AttemptService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

final class AutoSubmitAttempt implements ShouldQueue
{
    use Queueable;

    public function __construct(public readonly int $attemptId) {}

    public function handle(AttemptService $attempts): void
    {
        $attempt = Attempt::query()->find($this->attemptId);

        if ($attempt !== null) {
            $attempts->submit($attempt);
        }
    }
}
