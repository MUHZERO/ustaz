<?php

namespace App\Models;

use Database\Factories\ScoreHistoryFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['attempt_id', 'old_score', 'new_score', 'reason'])]
class ScoreHistory extends Model
{
    /** @use HasFactory<ScoreHistoryFactory> */
    use HasFactory;

    protected $table = 'score_history';

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return ['old_score' => 'decimal:2', 'new_score' => 'decimal:2'];
    }

    public function attempt(): BelongsTo
    {
        return $this->belongsTo(Attempt::class);
    }
}
