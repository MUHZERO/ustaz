<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\LockedException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\AnswerRequest;
use App\Http\Resources\AttemptResource;
use App\Http\Resources\ResultResource;
use App\Http\Resources\ReviewItemResource;
use App\Models\Assessment;
use App\Models\Attempt;
use App\Services\AttemptService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;

final class AttemptController extends Controller
{
    public function __construct(private readonly AttemptService $attempts) {}

    public function start(Request $request, Assessment $assessment): JsonResponse
    {
        [$attempt, $created] = $this->attempts->start($request->user(), $assessment);

        return AttemptResource::make($attempt->load(['assessment:id,kind', 'answers']))
            ->response()
            ->setStatusCode($created ? 201 : 200);
    }

    public function answer(AnswerRequest $request, Attempt $attempt): Response
    {
        $this->authorizeOwner($request, $attempt);
        $this->attempts->answer($attempt, $request->integer('question_id'), $request->integer('option_id'));

        return response()->noContent();
    }

    public function submit(Request $request, Attempt $attempt): ResultResource
    {
        $this->authorizeOwner($request, $attempt);

        return ResultResource::make($this->attempts->submit($attempt)->load('assessment'));
    }

    public function result(Request $request, Attempt $attempt): ResultResource
    {
        $this->authorizeOwner($request, $attempt);

        return ResultResource::make($attempt->load('assessment'));
    }

    public function review(Request $request, Attempt $attempt): AnonymousResourceCollection
    {
        $this->authorizeOwner($request, $attempt);

        if (! $this->attempts->reviewAvailable($attempt->load('assessment'))) {
            throw new LockedException;
        }

        return ReviewItemResource::collection($attempt->answers()->orderBy('id')->get());
    }

    /**
     * Another student's attempt answers 404, not 403, so ids cannot be probed.
     */
    private function authorizeOwner(Request $request, Attempt $attempt): void
    {
        abort_unless($request->user()->can('view', $attempt), 404);
    }
}
