<?php

namespace App\Services;

use App\Enums\AssessmentKind;
use App\Enums\AttemptStatus;
use App\Http\Resources\AnnouncementResource;
use App\Models\Announcement;
use App\Models\Assessment;
use App\Models\Attempt;
use App\Models\Category;
use App\Models\Lecture;
use App\Models\Level;
use App\Models\Paper;
use App\Models\Segment;
use App\Models\User;
use App\Models\WatchProgress;

final class ContentService
{
    public function __construct(
        private readonly CacheService $cache,
        private readonly AccessService $access
    ) {}

    public function levelTree(int $levelId): array
    {
        return $this->cache->remember(
            ["level:{$levelId}"],
            "level-tree:{$levelId}",
            3600,
            fn () => $this->buildLevelTree($levelId)
        );
    }

    public function announcements(int $levelId): array
    {
        return $this->cache->remember(
            ["level:{$levelId}"],
            "level-announcements:{$levelId}",
            3600,
            fn () => Announcement::query()
                ->where(fn ($q) => $q->where('level_id', $levelId)->orWhereNull('level_id'))
                ->whereNotNull('published_at')
                ->where('published_at', '<=', now())
                ->orderByDesc('published_at')
                ->limit(5)
                ->get(['id', 'title', 'body', 'image_path', 'published_at', 'level_id'])
                ->pipe(fn ($rows) => AnnouncementResource::collection($rows)->resolve())
        );
    }

    public function studentState(User $user): array
    {
        return $this->cache->remember(
            ["student:{$user->id}"],
            "student-state:{$user->id}",
            600,
            fn () => $this->loadStudentState($user)
        );
    }

    public function flushLevel(int $levelId): void
    {
        $this->cache->flush(["level:{$levelId}"]);
    }

    public function flushAllLevels(): void
    {
        $levelIds = Level::pluck('id');
        foreach ($levelIds as $id) {
            $this->cache->flush(["level:{$id}"]);
        }
    }

    private function buildLevelTree(int $levelId): array
    {
        $categories = Category::query()
            ->where('level_id', $levelId)
            ->orderBy('position')
            ->get(['id', 'level_id', 'name', 'position', 'is_free']);

        $categoryIds = $categories->pluck('id');

        $lectures = Lecture::query()
            ->whereIn('category_id', $categoryIds)
            ->whereNotNull('published_at')
            ->where('published_at', '<=', now())
            ->orderBy('position')
            ->get(['id', 'category_id', 'title', 'description', 'position', 'is_free', 'thumbnail_path']);

        $lectureIds = $lectures->pluck('id');

        $segments = Segment::query()
            ->whereIn('lecture_id', $lectureIds)
            ->orderBy('position')
            ->get(['id', 'lecture_id', 'type', 'position', 'title', 'is_gating', 'youtube_id', 'duration_seconds', 'pdf_path', 'assessment_id', 'pass_percent']);

        $exams = Assessment::query()
            ->whereIn('category_id', $categoryIds)
            ->where('kind', AssessmentKind::Exam)
            ->orderBy('opens_at')
            ->get(['id', 'category_id', 'title', 'opens_at', 'closes_at', 'duration_minutes', 'max_attempts', 'is_free']);

        $papers = Paper::query()
            ->whereIn('category_id', $categoryIds)
            ->get(['id', 'category_id', 'title', 'path']);

        $lecturesByCategory = $lectures->groupBy('category_id');
        $segmentsByLecture = $segments->groupBy('lecture_id');
        $examsByCategory = $exams->groupBy('category_id');
        $papersByCategory = $papers->groupBy('category_id');

        return $categories->map(fn ($cat) => [
            'id' => $cat->id,
            'level_id' => $cat->level_id,
            'name' => $cat->name,
            'position' => $cat->position,
            'is_free' => $cat->is_free,
            'lectures' => ($lecturesByCategory[$cat->id] ?? collect())->map(fn ($lec) => [
                'id' => $lec->id,
                'level_id' => $cat->level_id,
                'category_id' => $lec->category_id,
                'title' => $lec->title,
                'description' => $lec->description,
                'position' => $lec->position,
                'is_free' => $lec->is_free,
                'thumbnail_path' => $lec->thumbnail_path,
                'segments' => ($segmentsByLecture[$lec->id] ?? collect())->map(fn ($seg) => [
                    'id' => $seg->id,
                    'type' => $seg->type->value,
                    'position' => $seg->position,
                    'title' => $seg->title,
                    'is_gating' => $seg->is_gating,
                    'youtube_id' => $seg->youtube_id,
                    'duration_seconds' => $seg->duration_seconds,
                    'pdf_path' => $seg->pdf_path,
                    'assessment_id' => $seg->assessment_id,
                    'pass_percent' => $seg->pass_percent,
                ])->values()->all(),
            ])->values()->all(),
            'exams' => ($examsByCategory[$cat->id] ?? collect())->map(fn ($exam) => [
                'id' => $exam->id,
                'title' => $exam->title,
                'opens_at' => $exam->opens_at?->toIso8601String(),
                'closes_at' => $exam->closes_at?->toIso8601String(),
                'duration_minutes' => $exam->duration_minutes,
                'max_attempts' => $exam->max_attempts,
                'is_free' => $exam->is_free,
            ])->values()->all(),
            'papers' => ($papersByCategory[$cat->id] ?? collect())->map(fn ($paper) => [
                'id' => $paper->id,
                'title' => $paper->title,
                'path' => $paper->path,
            ])->values()->all(),
        ])->values()->all();
    }

    /**
     * @return array{progress: array<int, array{last_position_seconds: int, watched_seconds: int, completed: bool}>, best_ratios: array<int, float>, attempts: array<int, array{id: int, status: string, percent: float|null}>}
     */
    private function loadStudentState(User $user): array
    {
        $progress = WatchProgress::query()
            ->where('user_id', $user->id)
            ->get(['segment_id', 'last_position_seconds', 'watched_seconds', 'completed_at'])
            ->mapWithKeys(fn (WatchProgress $row) => [$row->segment_id => [
                'last_position_seconds' => $row->last_position_seconds,
                'watched_seconds' => $row->watched_seconds,
                'completed' => $row->completed_at !== null,
            ]])
            ->all();

        $attempts = Attempt::query()
            ->where('user_id', $user->id)
            ->orderBy('id')
            ->get(['id', 'assessment_id', 'status', 'score', 'max_score']);

        $percent = fn (Attempt $attempt) => (float) $attempt->max_score > 0 && $attempt->score !== null
            ? round((float) $attempt->score / (float) $attempt->max_score * 100, 2)
            : null;

        return [
            'progress' => $progress,
            'best_ratios' => $attempts
                ->filter(fn (Attempt $attempt) => $attempt->status === AttemptStatus::Submitted)
                ->groupBy('assessment_id')
                ->map(fn ($rows) => $rows->map(fn (Attempt $attempt) => ($percent($attempt) ?? 0) / 100)->max())
                ->all(),
            'attempts' => $attempts
                ->groupBy('assessment_id')
                ->map(fn ($rows) => [
                    'id' => $rows->last()->id,
                    'status' => $rows->last()->status->value,
                    'percent' => $percent($rows->last()),
                ])
                ->all(),
        ];
    }
}
