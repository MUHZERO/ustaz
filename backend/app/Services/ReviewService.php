<?php

namespace App\Services;

use App\Enums\AssessmentKind;
use App\Enums\AttemptStatus;
use App\Enums\ReviewStatus;
use App\Exceptions\LockedException;
use App\Exceptions\ReviewAlreadyRequestedException;
use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\ReviewRequest;
use App\Models\ScoreHistory;
use App\Models\User;
use App\Notifications\StudentNotification;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;

final class ReviewService
{
    public function __construct(
        private readonly ScoringService $scoring,
        private readonly AccessService $access,
    ) {}

    public function request(Attempt $attempt, string $note): ReviewRequest
    {
        $attempt->loadMissing('assessment:id,kind');

        if ($attempt->assessment->kind !== AssessmentKind::Exam || $attempt->status !== AttemptStatus::Submitted) {
            throw new LockedException;
        }

        try {
            return $attempt->reviewRequest()->create(['note' => $note, 'status' => ReviewStatus::Pending]);
        } catch (UniqueConstraintViolationException) {
            throw new ReviewAlreadyRequestedException;
        }
    }

    public function decide(ReviewRequest $request, ReviewStatus $status, ?string $reply, User $by): void
    {
        $request->update(['status' => $status, 'reply' => $reply, 'handled_by' => $by->id]);

        $student = $request->attempt()->firstOrFail()->user()->firstOrFail();
        $student->notify(new StudentNotification(
            __('api.notifications.review_decided'),
            (string) $reply,
            ['route' => 'result', 'attempt_id' => $request->attempt_id],
        ));
    }

    /**
     * Applies a new answer key to every past answer of the question, re-scores
     * the touched attempts with history, and notifies each affected student once.
     */
    public function rescoreQuestion(int $questionId, int $correctOptionId): void
    {
        $attemptIds = [];

        AttemptAnswer::query()
            ->where('question_id', $questionId)
            ->select(['id', 'attempt_id', 'snapshot'])
            ->chunkById(500, function ($answers) use ($correctOptionId, &$attemptIds) {
                DB::transaction(function () use ($answers, $correctOptionId, &$attemptIds) {
                    foreach ($answers as $answer) {
                        $snapshot = $answer->snapshot;
                        $snapshot['correct_option_id'] = $correctOptionId;
                        AttemptAnswer::query()->whereKey($answer->id)->update(['snapshot' => json_encode($snapshot)]);
                        $attemptIds[$answer->attempt_id] = true;
                    }
                });
            });

        $notify = [];

        foreach (array_chunk(array_keys($attemptIds), 500) as $chunk) {
            Attempt::query()
                ->whereIn('id', $chunk)
                ->where('status', AttemptStatus::Submitted)
                ->get()
                ->each(function (Attempt $attempt) use (&$notify) {
                    $old = (float) $attempt->score;
                    $this->scoring->score($attempt);

                    if ((float) $attempt->score !== $old) {
                        ScoreHistory::query()->create([
                            'attempt_id' => $attempt->id,
                            'old_score' => $old,
                            'new_score' => $attempt->score,
                            'reason' => 'answer_key_changed',
                        ]);
                        $notify[$attempt->user_id] = true;
                    }
                });
        }

        User::query()->whereIn('id', array_keys($notify))->each(function (User $student) {
            $this->access->flushStudent($student);
            $student->notify(new StudentNotification(__('api.notifications.score_changed'), '', ['route' => 'results']));
        });
    }
}
