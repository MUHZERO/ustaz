<?php

use App\Enums\AssessmentKind;
use App\Enums\AttemptStatus;
use App\Enums\SegmentType;
use App\Models\Assessment;
use App\Models\Attempt;
use App\Models\Category;
use App\Models\Lecture;
use App\Models\Level;
use App\Models\Segment;
use App\Models\Subscription;
use App\Models\User;
use App\Models\WatchProgress;
use App\Services\AnalyticsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->level = Level::factory()->create();
    $this->category = Category::factory()->for($this->level)->create();
    $this->lecture = Lecture::factory()->for($this->category)->create();
    $this->video = Segment::factory()->for($this->lecture)->create(['type' => SegmentType::Video, 'youtube_id' => 'x', 'duration_seconds' => 100, 'position' => 1]);
});

function subscribed(Category $category, int $count = 1)
{
    return User::factory()->student()->count($count)->create(['level_id' => $category->level_id])
        ->each(fn (User $student) => Subscription::factory()->for($student)->for($category)->create());
}

it('lecture report lists subscribed students who never watched', function () {
    [$watcher, $idle] = subscribed($this->category, 2);
    WatchProgress::factory()->for($watcher)->create(['segment_id' => $this->video->id, 'watched_seconds' => 50, 'last_position_seconds' => 50]);

    $rows = app(AnalyticsService::class)->lectureReport($this->lecture)->keyBy('student_id');

    expect($rows[$watcher->id]['watched_percent'])->toBe(50)
        ->and($rows[$idle->id]['watched_percent'])->toBe(0)
        ->and($rows[$idle->id]['subscribed'])->toBeTrue()
        ->and(app(AnalyticsService::class)->notWatched($this->lecture)->pluck('id')->all())->toBe([$idle->id]);
});

it('exam report counts absent subscribed students', function () {
    $exam = Assessment::factory()->create(['kind' => AssessmentKind::Exam, 'category_id' => $this->category->id]);
    [$a, $b, $absent] = subscribed($this->category, 3);
    Attempt::factory()->for($a)->for($exam)->create(['status' => AttemptStatus::Submitted, 'score' => 8, 'max_score' => 10]);
    Attempt::factory()->for($b)->for($exam)->create(['status' => AttemptStatus::Submitted, 'score' => 4, 'max_score' => 10]);

    $report = app(AnalyticsService::class)->examReport($exam);

    expect($report['average'])->toBe(60.0)
        ->and($report['absent']->pluck('id')->all())->toBe([$absent->id])
        ->and(array_sum($report['distribution']))->toBe(2);
});

it('analytics uses constant queries for 500 students', function () {
    subscribed($this->category, 500);
    DB::enableQueryLog();

    app(AnalyticsService::class)->lectureReport($this->lecture);

    expect(count(DB::getQueryLog()))->toBeLessThanOrEqual(5);
});
