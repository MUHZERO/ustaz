<?php

namespace App\Services;

use App\Enums\AssessmentKind;
use App\Enums\AttemptStatus;
use App\Enums\ShowAnswers;
use App\Exceptions\AlreadySubmittedException;
use App\Exceptions\ExamNotOpenException;
use App\Exceptions\LockedException;
use App\Jobs\AutoSubmitAttempt;
use App\Models\Assessment;
use App\Models\Attempt;
use App\Models\Question;
use App\Models\User;
use Carbon\CarbonInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

final class AttemptService
{
    public function __construct(
        private readonly AccessService $access,
        private readonly ScoringService $scoring,
    ) {}

    /**
     * Returns the open attempt if there is one; otherwise snapshots the questions
     * into a new attempt. The boolean is true when a new attempt was created.
     *
     * @return array{0: Attempt, 1: bool}
     */
    public function start(User $user, Assessment $assessment): array
    {
        if (! $this->access->canOpenAssessment($user, $assessment)) {
            throw new LockedException;
        }

        $open = $assessment->attempts()
            ->where('user_id', $user->id)
            ->where('status', AttemptStatus::InProgress)
            ->latest('id')
            ->first();

        if ($open !== null && ! $this->expired($open)) {
            return [$open, false];
        }

        if ($open !== null) {
            $this->submit($open);
        }

        $this->guardNewAttempt($user, $assessment);

        return [DB::transaction(fn () => $this->create($user, $assessment)), true];
    }

    public function answer(Attempt $attempt, int $questionId, int $optionId): void
    {
        if ($attempt->status === AttemptStatus::Submitted || $this->expired($attempt)) {
            throw new AlreadySubmittedException;
        }

        $attempt->answers()->where('question_id', $questionId)->update(['chosen_option_id' => $optionId]);
    }

    /**
     * Idempotent: a submitted attempt is returned unchanged.
     */
    public function submit(Attempt $attempt): Attempt
    {
        $submitted = DB::transaction(function () use ($attempt) {
            $locked = Attempt::query()->whereKey($attempt->id)->lockForUpdate()->firstOrFail();

            if ($locked->status === AttemptStatus::Submitted) {
                return $locked;
            }

            $this->scoring->score($locked);
            $locked->forceFill(['status' => AttemptStatus::Submitted, 'submitted_at' => now()])->save();

            return $locked;
        });

        $this->access->flushStudent($attempt->user()->firstOrFail());

        return $submitted;
    }

    public function reviewAvailable(Attempt $attempt): bool
    {
        if ($attempt->status !== AttemptStatus::Submitted) {
            return false;
        }

        $assessment = $attempt->relationLoaded('assessment') ? $attempt->assessment : $attempt->assessment()->firstOrFail();

        if ($assessment->kind !== AssessmentKind::Exam || $assessment->show_answers === ShowAnswers::AfterSubmit) {
            return true;
        }

        return $assessment->closes_at === null || $assessment->closes_at->isPast();
    }

    private function expired(Attempt $attempt): bool
    {
        return $attempt->deadline_at !== null && $attempt->deadline_at->isPast();
    }

    private function guardNewAttempt(User $user, Assessment $assessment): void
    {
        if ($assessment->kind !== AssessmentKind::Exam) {
            return;
        }

        $now = now();

        if (($assessment->opens_at && $now->lt($assessment->opens_at)) || ($assessment->closes_at && $now->gte($assessment->closes_at))) {
            throw new ExamNotOpenException;
        }

        $used = $assessment->attempts()->where('user_id', $user->id)->count();

        if ($assessment->max_attempts !== null && $used >= $assessment->max_attempts) {
            throw new AlreadySubmittedException;
        }
    }

    private function create(User $user, Assessment $assessment): Attempt
    {
        $now = now();
        $deadline = $this->deadline($assessment, $now);

        $attempt = $assessment->attempts()->create([
            'user_id' => $user->id,
            'status' => AttemptStatus::InProgress,
            'started_at' => $now,
            'deadline_at' => $deadline,
        ]);

        $questions = $assessment->questions()->with('options')->get();

        if ($assessment->shuffle) {
            $questions = $questions->shuffle();
        }

        $attempt->answers()->createMany($questions->values()->map(fn (Question $question) => [
            'question_id' => $question->id,
            'snapshot' => $this->snapshot($question, $assessment->shuffle),
        ])->all());

        if ($deadline !== null) {
            AutoSubmitAttempt::dispatch($attempt->id)->delay($deadline);
        }

        return $attempt;
    }

    private function deadline(Assessment $assessment, CarbonInterface $now): ?CarbonInterface
    {
        $byDuration = $assessment->duration_minutes ? $now->copy()->addMinutes($assessment->duration_minutes) : null;

        return collect([$byDuration, $assessment->closes_at])->filter()->min();
    }

    /**
     * @return array<string, mixed>
     */
    private function snapshot(Question $question, bool $shuffle): array
    {
        $options = $shuffle ? $question->options->shuffle() : $question->options;

        return [
            'text' => $question->text,
            'image_url' => $this->publicUrl($question->image_path),
            'explanation' => $question->explanation,
            'options' => $options->values()->map(fn ($option) => [
                'id' => $option->id,
                'text' => $option->text,
                'image_url' => $this->publicUrl($option->image_path),
            ])->all(),
            'correct_option_id' => $question->options->firstWhere('is_correct', true)?->id,
            'mark' => (int) $question->pivot->mark,
        ];
    }

    private function publicUrl(?string $path): ?string
    {
        return $path ? Storage::disk('public')->url($path) : null;
    }
}
