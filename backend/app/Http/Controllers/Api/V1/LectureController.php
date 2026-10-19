<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\LockedException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\ProgressRequest;
use App\Services\StudentContent;
use App\Services\WatchProgressService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

final class LectureController extends Controller
{
    public function show(Request $request, int $lecture): JsonResponse
    {
        return response()->json(['data' => StudentContent::for($request->user())->lecture($lecture) ?? abort(404)]);
    }

    public function progress(ProgressRequest $request, int $lecture, WatchProgressService $progress): Response
    {
        $content = StudentContent::for($request->user());
        $data = $content->findLecture($lecture) ?? abort(404);
        $segmentId = (int) $request->validated('segment_id');

        if (in_array($segmentId, $content->lockedSegmentIds($data), true)) {
            throw new LockedException;
        }

        $progress->record(
            $request->user(),
            $segmentId,
            (int) $request->validated('position_seconds'),
            (int) $request->validated('watched_seconds'),
            (int) $request->targetSegment()?->duration_seconds,
        );

        return response()->noContent();
    }
}
