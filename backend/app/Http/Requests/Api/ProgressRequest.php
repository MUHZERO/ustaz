<?php

namespace App\Http\Requests\Api;

use App\Models\Segment;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ProgressRequest extends FormRequest
{
    private ?Segment $targetSegment = null;

    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        $maxSeconds = $this->targetSegment()?->duration_seconds;

        return [
            'segment_id' => [
                'required',
                'integer',
                Rule::exists('segments', 'id')->where('lecture_id', $this->route('lecture')),
            ],
            'position_seconds' => array_filter(['required', 'integer', 'min:0', $maxSeconds !== null ? 'max:'.($maxSeconds + 10) : null]),
            'watched_seconds' => array_filter(['required', 'integer', 'min:0', $maxSeconds !== null ? 'max:'.($maxSeconds + 10) : null]),
        ];
    }

    public function targetSegment(): ?Segment
    {
        return $this->targetSegment ??= Segment::query()
            ->whereKey((int) $this->input('segment_id'))
            ->where('lecture_id', $this->route('lecture'))
            ->first(['id', 'duration_seconds']);
    }
}
