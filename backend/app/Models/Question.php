<?php

namespace App\Models;

use Database\Factories\QuestionFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['text', 'image_path', 'explanation', 'difficulty', 'level_id', 'archived_at'])]
class Question extends Model
{
    /** @use HasFactory<QuestionFactory> */
    use HasFactory;

    protected static function booted(): void
    {
        // Past attempts keep their snapshots; a question in use is archived instead.
        static::deleting(fn (Question $question) => ! AttemptAnswer::query()->where('question_id', $question->id)->exists());
    }

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return ['difficulty' => 'integer', 'archived_at' => 'datetime'];
    }

    public function level(): BelongsTo
    {
        return $this->belongsTo(Level::class);
    }

    public function options(): HasMany
    {
        return $this->hasMany(QuestionOption::class)->orderBy('position');
    }

    public function lectures(): BelongsToMany
    {
        return $this->belongsToMany(Lecture::class);
    }

    public function assessments(): BelongsToMany
    {
        return $this->belongsToMany(Assessment::class)->withPivot('position', 'mark');
    }
}
