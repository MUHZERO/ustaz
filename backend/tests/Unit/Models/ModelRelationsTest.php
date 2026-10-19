<?php

use App\Enums\AssessmentKind;
use App\Enums\AttemptStatus;
use App\Enums\DeviceStatus;
use App\Enums\ReviewStatus;
use App\Enums\SegmentType;
use App\Enums\UserRole;
use App\Models\ActivationCode;
use App\Models\Assessment;
use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\Category;
use App\Models\Device;
use App\Models\Lecture;
use App\Models\Level;
use App\Models\Question;
use App\Models\Segment;
use App\Models\Subscription;
use App\Models\User;
use App\Models\WatchProgress;
use Carbon\CarbonInterface;
use Illuminate\Database\LazyLoadingViolationException;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

function contentTree(): array
{
    $level = Level::factory()->create();
    $category = Category::factory()->for($level)->create(['position' => 1]);
    $lecture = Lecture::factory()->for($category)->create();
    $assessment = Assessment::factory()->create(['kind' => AssessmentKind::Quiz, 'lecture_id' => $lecture->id]);
    $questions = Question::factory()->count(3)->withOptions(4)->create(['level_id' => $level->id]);
    foreach ($questions as $i => $question) {
        $assessment->questions()->attach($question, ['position' => $i + 1, 'mark' => 1]);
    }
    Segment::factory()->for($lecture)->create(['type' => SegmentType::Video, 'position' => 2, 'youtube_id' => 'abc', 'duration_seconds' => 600]);
    Segment::factory()->for($lecture)->create(['type' => SegmentType::Quiz, 'position' => 1, 'assessment_id' => $assessment->id, 'is_gating' => true, 'pass_percent' => 50]);

    return compact('level', 'category', 'lecture', 'assessment', 'questions');
}

it('builds the full content tree with factories', function () {
    ['category' => $category, 'lecture' => $lecture, 'assessment' => $assessment] = contentTree();

    $lecture->load('segments');
    $category->load('lectures');
    $assessment->load('questions.options');

    expect($lecture->segments->pluck('position')->all())->toBe([1, 2])
        ->and($lecture->segments->first()->type)->toBe(SegmentType::Quiz)
        ->and($category->lectures)->toHaveCount(1)
        ->and($assessment->questions)->toHaveCount(3)
        ->and($assessment->questions->first()->options)->toHaveCount(4)
        ->and($assessment->questions->first()->options->where('is_correct', true))->toHaveCount(1)
        ->and($assessment->questions->first()->pivot->mark)->toBe(1);
});

it('throws on lazy loading in tests', function () {
    ['category' => $category] = contentTree();
    Lecture::factory()->for($category)->create();

    $lectures = Lecture::query()->get();

    expect(fn () => $lectures->first()->segments)->toThrow(LazyLoadingViolationException::class);
});

it('casts enums, dates and json on student records', function () {
    ['category' => $category, 'assessment' => $assessment, 'questions' => $questions] = contentTree();
    $student = User::factory()->student()->create();

    $subscription = Subscription::factory()->for($student)->for($category)->create(['ends_at' => null]);
    $device = Device::factory()->for($student)->create();
    $attempt = Attempt::factory()->for($student)->for($assessment)->create();
    $answer = AttemptAnswer::factory()->for($attempt)->create([
        'question_id' => $questions[0]->id,
        'snapshot' => ['text' => 'q', 'options' => [['id' => 1, 'text' => 'a']], 'correct_option_id' => 1, 'mark' => 1],
    ]);
    $code = ActivationCode::factory()->for($category)->create(['max_uses' => 3]);
    $progress = WatchProgress::factory()->for($student)->create();

    expect($student->role)->toBe(UserRole::Student)
        ->and($subscription->ends_at)->toBeNull()
        ->and($subscription->starts_at)->toBeInstanceOf(CarbonInterface::class)
        ->and($device->status)->toBe(DeviceStatus::Active)
        ->and($attempt->status)->toBe(AttemptStatus::InProgress)
        ->and($answer->snapshot['correct_option_id'])->toBe(1)
        ->and($code->uses_count)->toBe(0)
        ->and(strlen($code->code))->toBe(10)
        ->and($progress->watched_seconds)->toBe(0)
        ->and(ReviewStatus::from('pending'))->toBe(ReviewStatus::Pending);
});

it('keeps one subscription per student and category', function () {
    ['category' => $category] = contentTree();
    $student = User::factory()->student()->create();
    Subscription::factory()->for($student)->for($category)->create();

    expect(fn () => Subscription::factory()->for($student)->for($category)->create())
        ->toThrow(QueryException::class);
});

it('keeps one watch progress row per student and segment', function () {
    $student = User::factory()->student()->create();
    $progress = WatchProgress::factory()->for($student)->create();

    expect(fn () => WatchProgress::factory()->for($student)->create(['segment_id' => $progress->segment_id]))
        ->toThrow(QueryException::class);
});
