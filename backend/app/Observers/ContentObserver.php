<?php

namespace App\Observers;

use App\Models\Announcement;
use App\Models\Assessment;
use App\Models\Category;
use App\Models\Lecture;
use App\Models\Paper;
use App\Models\Segment;
use App\Services\ContentService;
use Illuminate\Database\Eloquent\Model;

/**
 * Teacher edits invalidate the cached level tree. Level ids are read with one
 * small query (no lazy loading) and an unknown level flushes every level.
 */
final class ContentObserver
{
    public function __construct(private readonly ContentService $content) {}

    public function saved(Model $model): void
    {
        $this->flush($model);
    }

    public function deleted(Model $model): void
    {
        $this->flush($model);
    }

    private function flush(Model $model): void
    {
        $levelId = $this->levelId($model);

        $levelId === null ? $this->content->flushAllLevels() : $this->content->flushLevel($levelId);
    }

    private function levelId(Model $model): ?int
    {
        $categoryLevel = fn (?int $categoryId) => $categoryId === null
            ? null
            : Category::query()->whereKey($categoryId)->value('level_id');

        return match (true) {
            $model instanceof Category, $model instanceof Announcement => $model->level_id,
            $model instanceof Lecture, $model instanceof Paper => $categoryLevel($model->category_id),
            $model instanceof Assessment => $categoryLevel($model->category_id
                ?? Lecture::query()->whereKey($model->lecture_id)->value('category_id')),
            $model instanceof Segment => $categoryLevel(Lecture::query()->whereKey($model->lecture_id)->value('category_id')),
            default => null,
        };
    }
}
