<?php

namespace App\Jobs;

use App\Notifications\StudentNotification;
use App\Services\Push\NotificationAudience;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Notification;

/**
 * A teacher's broadcast, sent in chunks so a whole level never sits in memory.
 */
final class BroadcastNotification implements ShouldQueue
{
    use Queueable;

    public const CHUNK = 500;

    /** @param  'all'|'level'|'category'  $audience */
    public function __construct(
        public readonly string $title,
        public readonly string $body,
        public readonly string $audience,
        public readonly ?int $targetId = null,
    ) {}

    public function handle(): void
    {
        $query = match ($this->audience) {
            'level' => NotificationAudience::level((int) $this->targetId),
            'category' => NotificationAudience::category((int) $this->targetId),
            default => NotificationAudience::all(),
        };

        $query->select('id')->chunkById(self::CHUNK, fn ($students) => Notification::send(
            $students,
            new StudentNotification($this->title, $this->body, ['route' => 'notifications']),
        ));
    }
}
