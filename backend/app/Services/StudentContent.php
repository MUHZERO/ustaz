<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;

/**
 * One student's view of the cached level tree: adds subscription, lock, progress
 * and attempt fields and shapes everything as the API contract describes.
 * Reads only caches, so a warm request costs no content queries.
 */
final class StudentContent
{
    /** @var array<int, array<string, mixed>> */
    private array $tree;

    /** @var array<int, string|null> category id => subscription end */
    private array $ends;

    /** @var array<string, mixed> */
    private array $state;

    public function __construct(private readonly User $user, ContentService $content, private readonly AccessService $access)
    {
        $this->tree = $content->levelTree((int) $user->level_id);
        $this->ends = $access->subscriptionEnds($user);
        $this->state = $content->studentState($user);
    }

    public static function for(User $user): self
    {
        return app(self::class, ['user' => $user]);
    }

    /** @return array<int, array<string, mixed>> */
    public function categories(): array
    {
        return array_map(fn (array $category) => $this->categoryCard($category), $this->tree);
    }

    /** @return array<string, mixed>|null */
    public function category(int $id): ?array
    {
        $category = collect($this->tree)->firstWhere('id', $id);

        if ($category === null) {
            return null;
        }

        $open = $this->categoryOpen($category);

        return [
            'category' => $this->categoryCard($category),
            'lectures' => array_map(fn (array $lecture) => $this->lectureCard($lecture), $category['lectures']),
            'exams' => array_map(fn (array $exam) => $this->examCard($exam, $open), $category['exams']),
            'papers' => $open ? array_map(fn (array $paper) => [
                'id' => $paper['id'],
                'title' => $paper['title'],
                'url' => $this->signedFileUrl($paper['path']),
            ], $category['papers']) : [],
        ];
    }

    /** @return array<string, mixed>|null */
    public function lecture(int $id): ?array
    {
        $lecture = $this->findLecture($id);

        if ($lecture === null) {
            return null;
        }

        $locked = array_flip($this->lockedSegmentIds($lecture));

        return [
            'id' => $lecture['id'],
            'title' => $lecture['title'],
            'description' => $lecture['description'],
            'is_free' => $lecture['is_free'],
            'is_locked' => ! $this->lectureOpen($lecture),
            'category_id' => $lecture['category_id'],
            'segments' => array_map(fn (array $segment) => $this->segment($segment, isset($locked[$segment['id']])), $lecture['segments']),
        ];
    }

    /** @return array<string, mixed> */
    public function home(array $announcements): array
    {
        $lectures = collect($this->tree)->flatMap(fn (array $category) => array_map(
            fn (array $lecture) => $lecture + ['category_is_free' => $category['is_free']],
            $category['lectures'],
        ));

        return [
            'announcements' => $announcements,
            'continue_watching' => $lectures
                ->filter(fn (array $lecture) => $this->lectureOpen($lecture) && $this->inProgress($lecture))
                ->take(5)
                ->map(fn (array $lecture) => $this->lectureCard($lecture))
                ->values()->all(),
            'categories' => $this->categories(),
            'free' => $lectures
                ->filter(fn (array $lecture) => $lecture['is_free'] || $lecture['category_is_free'])
                ->take(10)
                ->map(fn (array $lecture) => $this->lectureCard($lecture))
                ->values()->all(),
        ];
    }

    /** @return array<string, mixed>|null */
    public function findLecture(int $id): ?array
    {
        foreach ($this->tree as $category) {
            foreach ($category['lectures'] as $lecture) {
                if ($lecture['id'] === $id) {
                    return $lecture + ['category_is_free' => $category['is_free']];
                }
            }
        }

        return null;
    }

    /** @return array<int, int> */
    public function lockedSegmentIds(array $lecture): array
    {
        if (! $this->lectureOpen($lecture)) {
            return array_column($lecture['segments'], 'id');
        }

        return $this->access->lockedAfterGates($lecture['segments'], $this->state['best_ratios']);
    }

    private function categoryOpen(array $category): bool
    {
        return $category['is_free'] || array_key_exists($category['id'], $this->ends);
    }

    private function lectureOpen(array $lecture): bool
    {
        return $lecture['is_free'] || $lecture['category_is_free'] || array_key_exists($lecture['category_id'], $this->ends);
    }

    private function inProgress(array $lecture): bool
    {
        $rows = array_filter(array_map(fn (array $segment) => $this->state['progress'][$segment['id']] ?? null, $lecture['segments']));

        return $rows !== [] && ! collect($rows)->every(fn (array $row) => $row['completed']);
    }

    /** @return array<string, mixed> */
    private function categoryCard(array $category): array
    {
        return [
            'id' => $category['id'],
            'name' => $category['name'],
            'position' => $category['position'],
            'is_free' => $category['is_free'],
            'is_subscribed' => array_key_exists($category['id'], $this->ends),
            'ends_at' => $this->ends[$category['id']] ?? null,
            'lectures_count' => count($category['lectures']),
            'exams_count' => count($category['exams']),
            'papers_count' => count($category['papers']),
        ];
    }

    /** @return array<string, mixed> */
    private function lectureCard(array $lecture): array
    {
        $lecture += ['category_is_free' => $this->categoryIsFree($lecture['category_id'])];

        return [
            'id' => $lecture['id'],
            'title' => $lecture['title'],
            'position' => $lecture['position'],
            'is_free' => $lecture['is_free'],
            'is_locked' => ! $this->lectureOpen($lecture),
            'progress_percent' => $this->progressPercent($lecture),
            'thumbnail_url' => $lecture['thumbnail_path'] ? Storage::disk('public')->url($lecture['thumbnail_path']) : null,
        ];
    }

    /** @return array<string, mixed> */
    private function examCard(array $exam, bool $categoryOpen): array
    {
        $now = Carbon::now();
        $opensAt = $exam['opens_at'] ? Carbon::parse($exam['opens_at']) : null;
        $closesAt = $exam['closes_at'] ? Carbon::parse($exam['closes_at']) : null;

        return [
            'id' => $exam['id'],
            'title' => $exam['title'],
            'opens_at' => $exam['opens_at'],
            'closes_at' => $exam['closes_at'],
            'duration_minutes' => $exam['duration_minutes'],
            'state' => match (true) {
                $opensAt !== null && $now->lt($opensAt) => 'upcoming',
                $closesAt !== null && $now->gte($closesAt) => 'closed',
                default => 'open',
            },
            'attempt' => $this->state['attempts'][$exam['id']] ?? null,
            'is_locked' => ! ($exam['is_free'] || $categoryOpen),
        ];
    }

    /** @return array<string, mixed> */
    private function segment(array $segment, bool $locked): array
    {
        $data = [
            'id' => $segment['id'],
            'type' => $segment['type'],
            'position' => $segment['position'],
            'title' => $segment['title'],
            'is_gating' => $segment['is_gating'],
            'is_locked' => $locked,
            'passed' => $segment['assessment_id'] !== null && $segment['is_gating']
                ? ($this->state['best_ratios'][$segment['assessment_id']] ?? 0) * 100 >= ($segment['pass_percent'] ?? 0)
                : null,
        ];

        if ($locked) {
            return $data;
        }

        return $data + match ($segment['type']) {
            'video' => ['video' => [
                'youtube_id' => $segment['youtube_id'],
                'duration_seconds' => $segment['duration_seconds'],
                'last_position_seconds' => $this->state['progress'][$segment['id']]['last_position_seconds'] ?? 0,
            ]],
            'pdf' => ['pdf' => ['url' => $this->signedFileUrl($segment['pdf_path'])]],
            'quiz' => ['quiz' => [
                'assessment_id' => $segment['assessment_id'],
                'pass_percent' => $segment['pass_percent'],
                'best_percent' => isset($this->state['best_ratios'][$segment['assessment_id']])
                    ? round($this->state['best_ratios'][$segment['assessment_id']] * 100, 2)
                    : null,
            ]],
            default => [],
        };
    }

    private function progressPercent(array $lecture): int
    {
        $videos = array_filter($lecture['segments'], fn (array $segment) => $segment['type'] === 'video' && $segment['duration_seconds']);
        $total = array_sum(array_column($videos, 'duration_seconds'));

        if ($total === 0) {
            return 0;
        }

        $watched = array_sum(array_map(
            fn (array $segment) => min($this->state['progress'][$segment['id']]['watched_seconds'] ?? 0, $segment['duration_seconds']),
            $videos,
        ));

        return (int) floor($watched / $total * 100);
    }

    private function categoryIsFree(int $categoryId): bool
    {
        return (bool) (collect($this->tree)->firstWhere('id', $categoryId)['is_free'] ?? false);
    }

    private function signedFileUrl(string $path): string
    {
        return URL::temporarySignedRoute('files.show', now()->addMinutes(30), ['path' => $path]);
    }
}
