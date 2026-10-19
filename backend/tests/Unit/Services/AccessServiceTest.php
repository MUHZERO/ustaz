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
use App\Services\AccessService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->level = Level::factory()->create();
    $this->student = User::factory()->student()->create(['level_id' => $this->level->id]);
    $this->category = Category::factory()->for($this->level)->create(['is_free' => false]);
    $this->access = app(AccessService::class);
});

function lectureWithGate(Category $category): array
{
    $lecture = Lecture::factory()->for($category)->create(['is_free' => false]);
    $quiz = Assessment::factory()->create(['kind' => AssessmentKind::Quiz, 'lecture_id' => $lecture->id]);
    $intro = Segment::factory()->for($lecture)->create(['type' => SegmentType::Video, 'position' => 1, 'youtube_id' => 'a', 'duration_seconds' => 60]);
    $gate = Segment::factory()->for($lecture)->create(['type' => SegmentType::Quiz, 'position' => 2, 'assessment_id' => $quiz->id, 'is_gating' => true, 'pass_percent' => 60]);
    $after = Segment::factory()->for($lecture)->create(['type' => SegmentType::Video, 'position' => 3, 'youtube_id' => 'b', 'duration_seconds' => 60]);
    $last = Segment::factory()->for($lecture)->create(['type' => SegmentType::Pdf, 'position' => 4, 'pdf_path' => 'x.pdf']);

    return compact('lecture', 'quiz', 'intro', 'gate', 'after', 'last');
}

function submittedAttempt(User $student, Assessment $quiz, float $score): Attempt
{
    return Attempt::factory()->for($student)->for($quiz)->create([
        'status' => AttemptStatus::Submitted, 'score' => $score, 'max_score' => 10, 'submitted_at' => now(),
    ]);
}

it('free category opens without subscription', function () {
    $free = Category::factory()->for($this->level)->create(['is_free' => true]);

    expect($this->access->canOpenCategory($this->student, $free))->toBeTrue()
        ->and($this->access->canOpenCategory($this->student, $this->category))->toBeFalse();
});

it('other level category never opens', function () {
    $other = Category::factory()->create(['is_free' => true]);
    Subscription::factory()->for($this->student)->for($other)->create(['ends_at' => null]);

    expect($this->access->canOpenCategory($this->student, $other))->toBeFalse();
});

it('subscription without end date is lifetime', function () {
    Subscription::factory()->for($this->student)->for($this->category)->create(['ends_at' => null]);
    $this->travel(5)->years();

    expect($this->access->canOpenCategory($this->student, $this->category))->toBeTrue()
        ->and($this->access->subscribedCategoryIds($this->student))->toBe([$this->category->id]);
});

it('expired subscription locks content even if cached', function () {
    Subscription::factory()->for($this->student)->for($this->category)->create(['ends_at' => now()->addDay()]);
    expect($this->access->canOpenCategory($this->student, $this->category))->toBeTrue();

    $this->travel(2)->days();

    expect($this->access->canOpenCategory($this->student, $this->category))->toBeFalse();
});

it('free lecture inside paid category opens', function () {
    $lecture = Lecture::factory()->for($this->category)->create(['is_free' => true]);
    $paid = Lecture::factory()->for($this->category)->create(['is_free' => false]);

    expect($this->access->canOpenLecture($this->student, $lecture))->toBeTrue()
        ->and($this->access->canOpenLecture($this->student, $paid))->toBeFalse();
});

it('free assessment opens and paid exam needs subscription', function () {
    $free = Assessment::factory()->create(['kind' => AssessmentKind::Exam, 'category_id' => $this->category->id, 'is_free' => true]);
    $paid = Assessment::factory()->create(['kind' => AssessmentKind::Exam, 'category_id' => $this->category->id, 'is_free' => false]);

    expect($this->access->canOpenAssessment($this->student, $free))->toBeTrue()
        ->and($this->access->canOpenAssessment($this->student, $paid))->toBeFalse();

    Subscription::factory()->for($this->student)->for($this->category)->create();
    expect($this->access->canOpenAssessment($this->student, $paid))->toBeTrue();
});

it('segments after unpassed gating quiz are locked', function () {
    Subscription::factory()->for($this->student)->for($this->category)->create();
    ['lecture' => $lecture, 'after' => $after, 'last' => $last, 'quiz' => $quiz] = lectureWithGate($this->category);
    submittedAttempt($this->student, $quiz, 5);

    expect($this->access->lockedSegmentIds($this->student, $lecture))->toBe([$after->id, $last->id]);
});

it('passing gating quiz unlocks next segments', function () {
    Subscription::factory()->for($this->student)->for($this->category)->create();
    ['lecture' => $lecture, 'quiz' => $quiz] = lectureWithGate($this->category);
    submittedAttempt($this->student, $quiz, 4);
    submittedAttempt($this->student, $quiz, 7);

    expect($this->access->lockedSegmentIds($this->student, $lecture))->toBe([]);
});

it('every segment is locked when the lecture cannot be opened', function () {
    ['lecture' => $lecture, 'intro' => $intro, 'gate' => $gate, 'after' => $after, 'last' => $last] = lectureWithGate($this->category);

    expect($this->access->lockedSegmentIds($this->student, $lecture))->toBe([$intro->id, $gate->id, $after->id, $last->id]);
});

it('locked segments use a fixed number of queries', function () {
    Subscription::factory()->for($this->student)->for($this->category)->create();
    ['lecture' => $lecture] = lectureWithGate($this->category);
    $lecture = Lecture::with('segments', 'category')->find($lecture->id);

    DB::enableQueryLog();
    $this->access->lockedSegmentIds($this->student, $lecture);

    expect(count(DB::getQueryLog()))->toBeLessThanOrEqual(2);
});
