<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Database\Query\Expression;
use Illuminate\Support\Facades\DB;

final class WatchProgressService
{
    private const COMPLETED_RATIO = 0.9;

    public function __construct(private readonly AccessService $access) {}

    /**
     * Upsert in one statement so concurrent ticks can never lower watched_seconds
     * or move completed_at. The student-state cache is flushed only when the
     * segment becomes completed; other progress shows within its 10-minute TTL.
     */
    public function record(User $user, int $segmentId, int $position, int $watched, int $durationSeconds): void
    {
        $completesNow = $durationSeconds > 0 && $watched >= $durationSeconds * self::COMPLETED_RATIO;
        $wasCompleted = $completesNow && DB::table('watch_progress')
            ->where(['user_id' => $user->id, 'segment_id' => $segmentId])
            ->whereNotNull('completed_at')
            ->exists();
        $now = now();

        DB::table('watch_progress')->upsert(
            [[
                'user_id' => $user->id,
                'segment_id' => $segmentId,
                'last_position_seconds' => $position,
                'watched_seconds' => $watched,
                'completed_at' => $completesNow ? $now : null,
                'created_at' => $now,
                'updated_at' => $now,
            ]],
            ['user_id', 'segment_id'],
            [
                'last_position_seconds' => $position,
                'watched_seconds' => $this->greatest('watch_progress.watched_seconds', $watched),
                'completed_at' => DB::raw('COALESCE(watch_progress.completed_at, '.($completesNow ? DB::getPdo()->quote($now->toDateTimeString()) : 'NULL').')'),
                'updated_at' => $now,
            ],
        );

        if ($completesNow && ! $wasCompleted) {
            $this->access->flushStudent($user);
        }
    }

    private function greatest(string $column, int $value): Expression
    {
        $function = DB::getDriverName() === 'sqlite' ? 'MAX' : 'GREATEST';

        return DB::raw("{$function}({$column}, {$value})");
    }
}
