<?php

use App\Enums\AssessmentKind;
use App\Enums\AttemptStatus;
use App\Enums\ReviewStatus;
use App\Jobs\RescoreQuestion;
use App\Models\Assessment;
use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\Category;
use App\Models\Level;
use App\Models\Question;
use App\Models\ScoreHistory;
use App\Models\Subscription;
use App\Models\User;
use App\Notifications\StudentNotification;
use App\Services\DeviceService;
use App\Services\ReviewService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Queue;

uses(RefreshDatabase::class);

const REVIEW_DEVICE = '77777777-7777-4777-8777-777777777777';

beforeEach(function () {
    $this->level = Level::factory()->create();
    $this->category = Category::factory()->for($this->level)->create();
    $this->student = User::factory()->student()->create(['level_id' => $this->level->id]);
    app(DeviceService::class)->bind($this->student, REVIEW_DEVICE);
    Subscription::factory()->for($this->student)->for($this->category)->create();
    $this->question = Question::factory()->withOptions(3)->create(['level_id' => $this->level->id]);
    $this->right = $this->question->options()->where('is_correct', true)->first();
    $this->wrong = $this->question->options()->where('is_correct', false)->first();
});

function reviewApi()
{
    return test()->actingAs(test()->student, 'sanctum')->withHeader('X-Device-Id', REVIEW_DEVICE);
}

function submittedAttemptOn(Question $question, User $student, int $chosenOptionId, AssessmentKind $kind = AssessmentKind::Exam): Attempt
{
    $assessment = Assessment::factory()->create(['kind' => $kind, 'category_id' => test()->category->id]);
    $assessment->questions()->attach($question, ['position' => 1, 'mark' => 2]);
    $correct = $question->options()->where('is_correct', true)->value('id');
    $attempt = Attempt::factory()->for($student)->for($assessment)->create([
        'status' => AttemptStatus::Submitted, 'submitted_at' => now(), 'score' => $chosenOptionId === $correct ? 2 : 0, 'max_score' => 2,
    ]);
    AttemptAnswer::factory()->for($attempt)->create([
        'question_id' => $question->id,
        'snapshot' => ['text' => $question->text, 'image_url' => null, 'explanation' => null, 'options' => [], 'correct_option_id' => $correct, 'mark' => 2],
        'chosen_option_id' => $chosenOptionId,
        'is_correct' => $chosenOptionId === $correct,
    ]);

    return $attempt;
}

it('student can request review once per exam', function () {
    $attempt = submittedAttemptOn($this->question, $this->student, $this->wrong->id);

    reviewApi()->postJson("/api/v1/attempts/{$attempt->id}/review-request", ['note' => 'السؤال الأول له إجابتان'])
        ->assertOk()->assertJsonPath('data.review_request.status', 'pending');

    reviewApi()->postJson("/api/v1/attempts/{$attempt->id}/review-request", ['note' => 'مرة أخرى'])
        ->assertStatus(409)->assertJsonPath('code', 'review_already_requested');
});

it('review note is required and limited', function () {
    $attempt = submittedAttemptOn($this->question, $this->student, $this->wrong->id);

    reviewApi()->postJson("/api/v1/attempts/{$attempt->id}/review-request", ['note' => ''])->assertStatus(422);
    reviewApi()->postJson("/api/v1/attempts/{$attempt->id}/review-request", ['note' => str_repeat('a', 501)])->assertStatus(422);
});

it('quiz attempts cannot request review', function () {
    $attempt = submittedAttemptOn($this->question, $this->student, $this->wrong->id, AssessmentKind::Quiz);

    reviewApi()->postJson("/api/v1/attempts/{$attempt->id}/review-request", ['note' => 'x'])->assertForbidden()->assertJsonPath('code', 'locked');
});

it('teacher decision notifies student', function () {
    Notification::fake();
    $attempt = submittedAttemptOn($this->question, $this->student, $this->wrong->id);
    $request = app(ReviewService::class)->request($attempt, 'راجع من فضلك');
    $teacher = User::factory()->teacher()->create();

    app(ReviewService::class)->decide($request, ReviewStatus::Accepted, 'تم التصحيح', $teacher);

    expect($request->fresh()->status)->toBe(ReviewStatus::Accepted)->and($request->fresh()->handled_by)->toBe($teacher->id);
    Notification::assertSentTo($this->student, StudentNotification::class);
    reviewApi()->getJson("/api/v1/attempts/{$attempt->id}/result")->assertJsonPath('data.review_request.reply', 'تم التصحيح');
});

it('rescoring chunks attempts and keeps history', function () {
    Notification::fake();
    $students = User::factory()->student()->count(3)->create(['level_id' => $this->level->id]);
    $attempts = collect(range(1, 1200))->map(fn ($i) => submittedAttemptOn($this->question, $students[$i % 3], $i % 2 ? $this->wrong->id : $this->right->id));

    Queue::fake();
    $started = microtime(true);
    $this->wrong->update(['is_correct' => true]);
    $this->right->update(['is_correct' => false]);
    expect(microtime(true) - $started)->toBeLessThan(0.2);
    Queue::assertPushed(RescoreQuestion::class, 1);

    (new RescoreQuestion($this->question->id, $this->wrong->id))->handle(app(ReviewService::class));

    expect(Attempt::query()->whereIn('id', $attempts->filter(fn ($a, $i) => $i % 2 === 0)->pluck('id'))->where('score', 2)->count())->toBe(600)
        ->and(ScoreHistory::query()->where('reason', 'answer_key_changed')->count())->toBe(1200)
        ->and(AttemptAnswer::query()->where('is_correct', true)->count())->toBe(600);
    Notification::assertSentTimes(StudentNotification::class, 3);
});

it('editing question text does not touch past snapshots', function () {
    $attempt = submittedAttemptOn($this->question, $this->student, $this->wrong->id);
    $before = $attempt->answers()->first()->snapshot;

    $this->question->update(['text' => 'نص جديد']);

    expect($attempt->answers()->first()->snapshot)->toBe($before);
});

it('question with attempts cannot be deleted', function () {
    submittedAttemptOn($this->question, $this->student, $this->wrong->id);

    expect($this->question->delete())->toBeFalse()
        ->and(Question::query()->whereKey($this->question->id)->exists())->toBeTrue();
});

it('question without attempts can be deleted', function () {
    expect($this->question->delete())->toBeTrue();
});
