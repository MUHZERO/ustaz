<?php

namespace App\Jobs;

use App\Services\ActivationCodeService;
use Carbon\CarbonInterface;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

final class GenerateCodeBatch implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public readonly string $batchId,
        public readonly int $categoryId,
        public readonly int $count,
        public readonly int $maxUses,
        public readonly ?CarbonInterface $endsAt,
        public readonly ?CarbonInterface $expiresAt,
    ) {}

    public function handle(ActivationCodeService $codes): void
    {
        $codes->fillBatch($this->batchId, $this->categoryId, $this->count, $this->maxUses, $this->endsAt, $this->expiresAt);
    }
}
