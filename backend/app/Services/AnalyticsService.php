<?php

namespace App\Services;

use App\Enums\AttemptStatus;
use App\Enums\SegmentType;
use App\Enums\UserRole;
use App\Models\Assessment;
use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\Lecture;
use App\Models\User;
use App\Models\WatchProgress;
use App\Services\Push\NotificationAudience;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

/**
 * Teacher reports. Every report runs a fixed number of queries whatever the
 * number of students, and aggregates in PHP over narrow selects.
 */
final class AnalyticsService
{
    /**
     * One row per student who is subscribed to the lecture's category or has
     * watched any of its videos, keyed by student id.
     *
     * @return Collection<int, array{student_id: int, student: string, phone: string, subscribed: bool, watched_percent: int, completed_at: string|null}>
     */
    public function lectureReport(Lecture $lecture): Collection
    {
        $durations = $lecture->segments()->where('type', SegmentType::Video)->pluck('duration_seconds', 'id')->map(fn ($seconds) => (int) $seconds);
        $total = $durations->sum();

        $progress = WatchProgress::query()
            ->whereIn('segment_id', $durations->keys())
            ->get(['user_id', 'segment_id', 'watched_seconds', 'completed_at'])
            ->groupBy('user_id');

        return User::query()
            ->where('role', UserRole::Student)
            ->where(fn (Builder $query) => $query
                ->whereHas('subscriptions', fn (Builder $subscription) => $subscription->active()->where('category_id', $lecture->category_id))
                ->orWhereIn('id', $progress->keys()))
            ->withExists(['subscriptions as subscribed' => fn (Builder $subscription) => $subscription->active()->where('category_id', $lecture->category_id)])
            ->orderBy('name')
            ->get(['id', 'name', 'phone'])
            ->mapWithKeys(function (User $student) use ($progress, $durations, $total) {
                $rows = $progress->get($student->id, collect());
                $watched = $rows->sum(fn (WatchProgress $row) => min($row->watched_seconds, $durations[$row->segment_id] ?? 0));
                $completed = $durations->isNotEmpty() && $rows->whereNotNull('completed_at')->count() === $durations->count();

                return [$student->id => [
                    'student_id' => $student->id,
                    'student' => $student->name,
                    'phone' => $student->phone,
                    'subscribed' => (bool) $student->subscribed,
                    'watched_percent' => $total > 0 ? (int) floor($watched / $total * 100) : 0,
                    'completed_at' => $completed ? $rows->max('completed_at')?->toDateTimeString() : null,
                ]];
            });
    }

    /** @return Collection<int, User> subscribed students with no progress on any of the lecture's segments */
    public function notWatched(Lecture $lecture): Collection
    {
        return NotificationAudience::category($lecture->category_id)
            ->whereDoesntHave('watchProgress', fn (Builder $query) => $query->whereIn('segment_id', $lecture->segments()->select('id')))
            ->get(['id', 'name', 'phone', 'parent_phone']);
    }

    /**
     * Uses each student's best submitted attempt. Distribution has ten 10 %
     * buckets; error rates are per question id, in percent.
     *
     * @return array{average: float|null, percents: Collection<int, float>, distribution: array<int, int>, error_rates: array<int, float>, absent: Collection<int, User>}
     */
    public function examReport(Assessment $assessment): array
    {
        $percents = Attempt::query()
            ->where('assessment_id', $assessment->id)
            ->where('status', AttemptStatus::Submitted)
            ->where('max_score', '>', 0)
            ->get(['user_id', 'score', 'max_score'])
            ->groupBy('user_id')
            ->map(fn (Collection $attempts) => $attempts->max(fn (Attempt $attempt) => $attempt->score / $attempt->max_score * 100));

        $distribution = array_fill(0, 10, 0);
        foreach ($percents as $percent) {
            $distribution[min(9, (int) floor($percent / 10))]++;
        }

        $errorRates = AttemptAnswer::query()
            ->whereHas('attempt', fn (Builder $query) => $query->where('assessment_id', $assessment->id)->where('status', AttemptStatus::Submitted))
            ->groupBy('question_id')
            ->selectRaw('question_id, count(*) as answers, sum(case when is_correct = 1 then 0 else 1 end) as wrong')
            ->get()
            ->mapWithKeys(fn ($row) => [(int) $row->question_id => round($row->wrong / $row->answers * 100, 2)])
            ->all();

        $categoryId = $assessment->category_id ?? $assessment->lecture()->value('category_id');

        return [
            'average' => $percents->isEmpty() ? null : round($percents->avg(), 2),
            'percents' => $percents,
            'distribution' => $distribution,
            'error_rates' => $errorRates,
            'absent' => $categoryId === null ? collect() : NotificationAudience::category($categoryId)
                ->whereDoesntHave('attempts', fn (Builder $query) => $query->where('assessment_id', $assessment->id)->where('status', AttemptStatus::Submitted))
                ->get(['id', 'name', 'phone', 'parent_phone']),
        ];
    }
}
