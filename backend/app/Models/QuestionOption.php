<?php

namespace App\Models;

use App\Jobs\RescoreQuestion;
use Database\Factories\QuestionOptionFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['question_id', 'text', 'image_path', 'is_correct', 'position'])]
class QuestionOption extends Model
{
    /** @use HasFactory<QuestionOptionFactory> */
    use HasFactory;

    protected static function booted(): void
    {
        // A new correct answer re-scores past attempts in the background.
        static::updated(function (QuestionOption $option) {
            if ($option->wasChanged('is_correct') && $option->is_correct) {
                RescoreQuestion::dispatch($option->question_id, $option->id);
            }
        });
    }

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return ['is_correct' => 'boolean', 'position' => 'integer'];
    }

    public function question(): BelongsTo
    {
        return $this->belongsTo(Question::class);
    }
}
