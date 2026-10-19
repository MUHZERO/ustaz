<?php

namespace App\Models;

use Database\Factories\WatchProgressFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['user_id', 'segment_id', 'last_position_seconds', 'watched_seconds', 'completed_at'])]
class WatchProgress extends Model
{
    /** @use HasFactory<WatchProgressFactory> */
    use HasFactory;

    protected $table = 'watch_progress';

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'last_position_seconds' => 'integer',
            'watched_seconds' => 'integer',
            'completed_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function segment(): BelongsTo
    {
        return $this->belongsTo(Segment::class);
    }
}
