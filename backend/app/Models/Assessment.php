<?php

namespace App\Models;

use App\Enums\AssessmentKind;
use App\Enums\ShowAnswers;
use Database\Factories\AssessmentFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['kind', 'title', 'category_id', 'lecture_id', 'opens_at', 'closes_at', 'duration_minutes', 'max_attempts', 'shuffle', 'show_answers', 'is_free'])]
class Assessment extends Model
{
    /** @use HasFactory<AssessmentFactory> */
    use HasFactory;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'kind' => AssessmentKind::class,
            'show_answers' => ShowAnswers::class,
            'opens_at' => 'datetime',
            'closes_at' => 'datetime',
            'duration_minutes' => 'integer',
            'max_attempts' => 'integer',
            'shuffle' => 'boolean',
            'is_free' => 'boolean',
        ];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function lecture(): BelongsTo
    {
        return $this->belongsTo(Lecture::class);
    }

    public function questions(): BelongsToMany
    {
        return $this->belongsToMany(Question::class)
            ->withPivot('position', 'mark')
            ->withCasts(['mark' => 'integer'])
            ->orderByPivot('position');
    }

    public function segments(): HasMany
    {
        return $this->hasMany(Segment::class);
    }

    public function attempts(): HasMany
    {
        return $this->hasMany(Attempt::class);
    }
}
