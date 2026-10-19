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
        return array_keys($this->subscriptionEnds($user));
    }

    /**
     * Active subscriptions as category id => ISO end date (null = lifetime), ascending by id.
     *
     * @return array<int, string|null>
     */
    public function subscriptionEnds(User $user): array
    {
        $tags = ["student:{$user->id}"];
        $key = "subscriptions:{$user->id}";

        $cached = $this->cache->remember($tags, $key, 600, fn () => $this->computeSubscriptions($user));

        if ($cached['valid_until'] !== null && now()->getTimestamp() >= $cached['valid_until']) {
            $this->cache->flush($tags);

            return $this->subscriptionEnds($user);
        }

        return $cached['ends'];
    }

    public function canOpenCategory(User $user, Category $category): bool
    {
        return $this->opens($user, $category, false);
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

        return $this->lockedAfterGates(
            $segments->map->only(['id', 'is_gating', 'assessment_id', 'pass_percent'])->all(),
            $this->bestGateRatios($user, $segments),
        );
    }

    /**
     * Segments after the first unpassed gating quiz are locked; the quiz itself stays open.
     *
     * @param  array<int, array{id: int, is_gating: bool, assessment_id: int|null, pass_percent: int|null}>  $segments  ordered by position
     * @param  array<int, float>  $bestRatios  assessment id => best score / max score
     * @return array<int, int>
     */
    public function lockedAfterGates(array $segments, array $bestRatios): array
    {
        $locked = [];
        $blocked = false;

        foreach ($segments as $segment) {
            if ($blocked) {
                $locked[] = $segment['id'];

                continue;
            }

            if ($segment['is_gating'] && $segment['assessment_id'] !== null) {
                $blocked = ($bestRatios[$segment['assessment_id']] ?? 0.0) * 100 < ($segment['pass_percent'] ?? 0);
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
     * @return array{ends: array<int, string|null>, valid_until: int|null}
     */
    private function computeSubscriptions(User $user): array
    {
        $subscriptions = $user->subscriptions()
            ->active()
            ->get(['category_id', 'ends_at']);

        $ends = $subscriptions
            ->sortBy('category_id')
            ->mapWithKeys(fn ($subscription) => [(int) $subscription->category_id => $subscription->ends_at?->toIso8601String()])
            ->all();

        return [
            'ends' => $ends,
            'valid_until' => $subscriptions->pluck('ends_at')->filter()->min()?->getTimestamp(),
        ];
    }

    /** Everything inside a free category is free, as in the student's content view. */
    private function opens(User $user, Category $category, bool $isFree): bool
    {
        if ($user->level_id !== $category->level_id) {
            return false;
        }

        return $isFree || $category->is_free || in_array($category->id, $this->subscribedCategoryIds($user), true);
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
