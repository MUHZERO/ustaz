<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\AssessmentKind;
use App\Enums\AttemptStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\ResultResource;
use App\Models\Assessment;
use App\Services\AccessService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

final class ResultController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        return ResultResource::collection(
            $request->user()->attempts()
                ->where('status', AttemptStatus::Submitted)
                ->with('assessment:id,title,kind,closes_at,show_answers')
                ->latest('submitted_at')
                ->paginate(20),
        );
    }

    public function homework(Request $request, AccessService $access): JsonResponse
    {
        $student = $request->user();

        $homework = Assessment::query()
            ->where('kind', AssessmentKind::Homework)
            ->whereHas('lecture.category', fn ($query) => $query->where('level_id', $student->level_id))
            ->with(['lecture.category', 'attempts' => fn ($query) => $query->where('user_id', $student->id)->latest('id')])
            ->orderBy('id')
            ->get()
            ->filter(fn (Assessment $assessment) => $access->canOpenLecture($student, $assessment->lecture))
            ->map(fn (Assessment $assessment) => [
                'assessment_id' => $assessment->id,
                'title' => $assessment->title,
                'lecture_id' => $assessment->lecture_id,
                'attempt' => ($attempt = $assessment->attempts->first()) === null ? null : [
                    'status' => $attempt->status->value,
                    'percent' => (float) $attempt->max_score > 0 ? round((float) $attempt->score / (float) $attempt->max_score * 100, 2) : null,
                ],
            ])
            ->values();

        return response()->json(['data' => $homework]);
    }
}
