<?php

namespace App\Services;

use App\Enums\AttemptStatus;
use App\Models\Assessment;
use App\Models\Attempt;
use App\Models\Category;
use App\Models\Lecture;
use App\Models\Segment;
use App\Models\User;
use Illuminate\Support\Collection;

final class AccessService
{
    public function __construct(private readonly CacheService $cache) {}

    /**
     * @return array<int, int>
     */
    public function subscribedCategoryIds(User $user): array
    {
        $tags = ["student:{$user->id}"];
        $key = "subscribed-categories:{$user->id}";

        $cached = $this->cache->remember($tags, $key, 600, fn () => $this->computeSubscriptions($user));

        if ($cached['valid_until'] !== null && now()->getTimestamp() >= $cached['valid_until']) {
            $this->cache->flush($tags);

            return $this->subscribedCategoryIds($user);
        }

        return $cached['ids'];
    }

    public function canOpenCategory(User $user, Category $category): bool
    {
        return $this->opens($user, $category, $category->is_free);
    }

    public function canOpenLecture(User $user, Lecture $lecture): bool
    {
        return $this->opens($user, $this->categoryOf($lecture), $lecture->is_free);
    }

    public function canOpenAssessment(User $user, Assessment $assessment): bool
    {
        if ($assessment->lecture_id !== null) {
            return $this->canOpenLecture($user, $this->lectureOf($assessment));
        }

        return $this->opens($user, $this->categoryOfAssessment($assessment), $assessment->is_free);
    }

    /**
     * @return array<int, int>
     */
    public function lockedSegmentIds(User $user, Lecture $lecture): array
    {
        $segments = $lecture->relationLoaded('segments')
            ? $lecture->segments
            : $lecture->segments()->orderBy('position')->get();

        if (! $this->canOpenLecture($user, $lecture)) {
            return $segments->pluck('id')->all();
        }

        $best = $this->bestGateRatios($user, $segments);

        $locked = [];
        $blocked = false;

        foreach ($segments as $segment) {
            if ($blocked) {
                $locked[] = $segment->id;

                continue;
            }

            if (! $segment->is_gating || $segment->assessment_id === null) {
                continue;
            }

            $percent = ($best[$segment->assessment_id] ?? 0.0) * 100;

            if ($percent < ($segment->pass_percent ?? 0)) {
                $blocked = true;
            }
        }

        return $locked;
    }

    public function flushStudent(User $user): void
    {
        $this->cache->flush(["student:{$user->id}"]);
    }

    /**
     * Subscription writes call flushStudent(), so an empty answer is safe to cache.
     *
     * @return array{ids: array<int, int>, valid_until: int|null}
     */
    private function computeSubscriptions(User $user): array
    {
        $subscriptions = $user->subscriptions()
            ->where(fn ($query) => $query->whereNull('ends_at')->orWhere('ends_at', '>', now()))
            ->get(['category_id', 'ends_at']);

        $ids = $subscriptions->pluck('category_id')->unique()->sort()->values()->all();
        $nearest = $subscriptions->pluck('ends_at')->filter()->min();

        return [
            'ids' => array_map('intval', $ids),
            'valid_until' => $nearest?->getTimestamp(),
        ];
    }

    private function opens(User $user, Category $category, bool $isFree): bool
    {
        if ($user->level_id !== $category->level_id) {
            return false;
        }

        return $isFree || in_array($category->id, $this->subscribedCategoryIds($user), true);
    }

    /**
     * @param  Collection<int, Segment>  $segments
     * @return array<int, float>
     */
    private function bestGateRatios(User $user, $segments): array
    {
        $gateIds = $segments
            ->where('is_gating', true)
            ->pluck('assessment_id')
            ->filter()
            ->unique()
            ->values();

        if ($gateIds->isEmpty()) {
            return [];
        }

        $attempts = Attempt::query()
            ->where('user_id', $user->id)
            ->whereIn('assessment_id', $gateIds)
            ->where('status', AttemptStatus::Submitted)
            ->get(['assessment_id', 'score', 'max_score']);

        $best = [];

        foreach ($attempts as $attempt) {
            $max = (float) $attempt->max_score;
            $ratio = $max > 0.0 ? (float) $attempt->score / $max : 0.0;
            $current = $best[$attempt->assessment_id] ?? 0.0;

            if ($ratio > $current) {
                $best[$attempt->assessment_id] = $ratio;
            }
        }

        return $best;
    }

    private function categoryOf(Lecture $lecture): Category
    {
        return $lecture->relationLoaded('category')
            ? $lecture->category
            : $lecture->category()->firstOrFail();
    }

    private function categoryOfAssessment(Assessment $assessment): Category
    {
        return $assessment->relationLoaded('category')
            ? $assessment->category
            : $assessment->category()->firstOrFail();
    }

    private function lectureOf(Assessment $assessment): Lecture
    {
        return $assessment->relationLoaded('lecture')
            ? $assessment->lecture
            : $assessment->lecture()->firstOrFail();
    }
}
