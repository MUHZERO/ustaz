<?php

namespace App\Models;

use App\Enums\SegmentType;
use Database\Factories\SegmentFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['lecture_id', 'type', 'position', 'title', 'is_gating', 'youtube_id', 'duration_seconds', 'pdf_path', 'assessment_id', 'pass_percent'])]
class Segment extends Model
{
    /** @use HasFactory<SegmentFactory> */
    use HasFactory;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'type' => SegmentType::class,
            'position' => 'integer',
            'is_gating' => 'boolean',
            'duration_seconds' => 'integer',
            'pass_percent' => 'integer',
        ];
    }

    public function lecture(): BelongsTo
    {
        return $this->belongsTo(Lecture::class);
    }

    public function assessment(): BelongsTo
    {
        return $this->belongsTo(Assessment::class);
    }
}
