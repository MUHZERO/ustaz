<?php

use App\Enums\AssessmentKind;
use App\Enums\AttemptStatus;
use App\Enums\ShowAnswers;
use App\Jobs\AutoSubmitAttempt;
use App\Models\Assessment;
use App\Models\Attempt;
use App\Models\Category;
use App\Models\Lecture;
use App\Models\Level;
use App\Models\Question;
use App\Models\Subscription;
use App\Models\User;
use App\Services\AttemptService;
use App\Services\DeviceService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;

uses(RefreshDatabase::class);

const ATTEMPT_DEVICE = '66666666-6666-4666-8666-666666666666';

beforeEach(function () {
    $this->level = Level::factory()->create();
    $this->category = Category::factory()->for($this->level)->create(['is_free' => false]);
    $this->student = User::factory()->student()->create(['level_id' => $this->level->id]);
    app(DeviceService::class)->bind($this->student, ATTEMPT_DEVICE);
    Subscription::factory()->for($this->student)->for($this->category)->create();
});

function attemptApi(?User $as = null)
{
    return test()->actingAs($as ?? test()->student, 'sanctum')->withHeader('X-Device-Id', ATTEMPT_DEVICE);
}

function makeAssessment(Category $category, array $attributes = [], int $questions = 3): Assessment
{
    $assessment = Assessment::factory()->create($attributes + ['category_id' => $category->id, 'kind' => AssessmentKind::Exam]);
    Question::factory()->count($questions)->withOptions(4)->create(['level_id' => $category->level_id])
        ->each(fn (Question $question, int $i) => $assessment->questions()->attach($question, ['position' => $i + 1, 'mark' => 2]));

    return $assessment;
}

function openExam(Category $category, array $attributes = []): Assessment
{
    return makeAssessment($category, $attributes + [
        'opens_at' => now()->subHour(), 'closes_at' => now()->addHours(2), 'duration_minutes' => 30, 'max_attempts' => 1,
    ]);
}

function correctOption(Assessment $assessment, int $index): array
{
    $question = $assessment->questions()->with('options')->get()[$index];

    return [$question->id, $question->options->firstWhere('is_correct', true)->id, $question->options->firstWhere('is_correct', false)->id];
}

it('starting twice resumes same attempt', function () {
    Queue::fake();
    $exam = openExam($this->category);

    $first = attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->assertCreated()->json('data.id');
    $second = attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->assertOk()->json('data.id');

    expect($second)->toBe($first)->and(Attempt::count())->toBe(1);
});

it('attempt payload has questions without answers', function () {
    Queue::fake();
    $exam = openExam($this->category);

    $response = attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->assertCreated()
        ->assertJsonCount(3, 'data.questions')
        ->assertJsonStructure(['data' => ['id', 'assessment_id', 'kind', 'started_at', 'deadline_at', 'status', 'answers',
            'questions' => [['id', 'text', 'image_url', 'options' => [['id', 'text', 'image_url']]]]]]);

    expect($response->getContent())->not->toContain('is_correct')->not->toContain('correct_option_id');
});

it('locked assessment cannot start', function () {
    $other = Category::factory()->for($this->level)->create(['is_free' => false]);
    $exam = openExam($other);

    attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->assertForbidden()->assertJsonPath('code', 'locked');
});

it('exam cannot start before opens_at', function () {
    $exam = openExam($this->category, ['opens_at' => now()->addHour()]);

    attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->assertStatus(409)->assertJsonPath('code', 'exam_not_open');
});

it('exam cannot start after closes_at', function () {
    $exam = openExam($this->category, ['opens_at' => now()->subHours(3), 'closes_at' => now()->subMinute()]);

    attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->assertStatus(409)->assertJsonPath('code', 'exam_not_open');
});

it('deadline is capped by closes_at', function () {
    Queue::fake();
    $exam = openExam($this->category, ['closes_at' => now()->addMinutes(10), 'duration_minutes' => 30]);

    $deadline = attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->json('data.deadline_at');

    expect(Carbon::parse($deadline)->diffInMinutes(now()->addMinutes(10), true))->toBeLessThan(1);
    Queue::assertPushed(AutoSubmitAttempt::class);
});

it('untimed quiz has no deadline and no auto submit', function () {
    Queue::fake();
    $quiz = makeAssessment($this->category, ['kind' => AssessmentKind::Quiz]);

    attemptApi()->postJson("/api/v1/assessments/{$quiz->id}/attempts")->assertCreated()->assertJsonPath('data.deadline_at', null);
    Queue::assertNotPushed(AutoSubmitAttempt::class);
});

it('answers autosave and submit scores', function () {
    Queue::fake();
    $exam = openExam($this->category);
    $attempt = attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->json('data.id');
    [$q1, $right1] = correctOption($exam, 0);
    [$q2, , $wrong2] = correctOption($exam, 1);

    attemptApi()->putJson("/api/v1/attempts/{$attempt}/answers", ['question_id' => $q1, 'option_id' => $right1])->assertNoContent();
    attemptApi()->putJson("/api/v1/attempts/{$attempt}/answers", ['question_id' => $q2, 'option_id' => $wrong2])->assertNoContent();

    attemptApi()->postJson("/api/v1/attempts/{$attempt}/submit")->assertOk()
        ->assertJsonPath('data.score', 2)
        ->assertJsonPath('data.max_score', 6)
        ->assertJsonPath('data.percent', 33.33);
});

it('submit twice returns same result', function () {
    Queue::fake();
    $exam = openExam($this->category);
    $attempt = attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->json('data.id');

    $first = attemptApi()->postJson("/api/v1/attempts/{$attempt}/submit")->assertOk()->json('data');
    $second = attemptApi()->postJson("/api/v1/attempts/{$attempt}/submit")->assertOk()->json('data');

    expect($second)->toBe($first);
});

it('late answer is rejected after deadline', function () {
    Queue::fake();
    $exam = openExam($this->category, ['duration_minutes' => 30]);
    $attempt = attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->json('data.id');
    [$q1, $right1] = correctOption($exam, 0);

    $this->travel(31)->minutes();

    attemptApi()->putJson("/api/v1/attempts/{$attempt}/answers", ['question_id' => $q1, 'option_id' => $right1])
        ->assertStatus(409)->assertJsonPath('code', 'already_submitted');
});

it('auto submit job scores saved answers', function () {
    Queue::fake();
    $exam = openExam($this->category);
    $attemptId = attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->json('data.id');
    [$q1, $right1] = correctOption($exam, 0);
    attemptApi()->putJson("/api/v1/attempts/{$attemptId}/answers", ['question_id' => $q1, 'option_id' => $right1]);

    $this->travel(31)->minutes();
    (new AutoSubmitAttempt($attemptId))->handle(app(AttemptService::class));

    $attempt = Attempt::find($attemptId);
    expect($attempt->status)->toBe(AttemptStatus::Submitted)->and((float) $attempt->score)->toBe(2.0);
});

it('max attempts reached blocks a new attempt', function () {
    Queue::fake();
    $exam = openExam($this->category, ['max_attempts' => 1]);
    $attempt = attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->json('data.id');
    attemptApi()->postJson("/api/v1/attempts/{$attempt}/submit");

    attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->assertStatus(409)->assertJsonPath('code', 'already_submitted');
});

it('quiz allows retakes', function () {
    $quiz = makeAssessment($this->category, ['kind' => AssessmentKind::Quiz]);
    $first = attemptApi()->postJson("/api/v1/assessments/{$quiz->id}/attempts")->json('data.id');
    attemptApi()->postJson("/api/v1/attempts/{$first}/submit");

    $second = attemptApi()->postJson("/api/v1/assessments/{$quiz->id}/attempts")->assertCreated()->json('data.id');

    expect($second)->not->toBe($first);
});

it('review hidden until exam closes when show_answers is after_close', function () {
    Queue::fake();
    $exam = openExam($this->category, ['show_answers' => ShowAnswers::AfterClose, 'closes_at' => now()->addHour()]);
    $attempt = attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->json('data.id');
    attemptApi()->postJson("/api/v1/attempts/{$attempt}/submit")->assertJsonPath('data.review_available', false);

    attemptApi()->getJson("/api/v1/attempts/{$attempt}/review")->assertForbidden()->assertJsonPath('code', 'locked');

    $this->travel(2)->hours();
    attemptApi()->getJson("/api/v1/attempts/{$attempt}/review")->assertOk()
        ->assertJsonCount(3, 'data')
        ->assertJsonStructure(['data' => [['question' => ['id', 'text', 'options'], 'chosen_option_id', 'correct_option_id', 'is_correct', 'explanation']]]);
});

it('quiz review is available right after submit', function () {
    $quiz = makeAssessment($this->category, ['kind' => AssessmentKind::Quiz]);
    $attempt = attemptApi()->postJson("/api/v1/assessments/{$quiz->id}/attempts")->json('data.id');

    attemptApi()->postJson("/api/v1/attempts/{$attempt}/submit")->assertJsonPath('data.review_available', true);
    attemptApi()->getJson("/api/v1/attempts/{$attempt}/review")->assertOk();
});

it('review is not available while in progress', function () {
    $quiz = makeAssessment($this->category, ['kind' => AssessmentKind::Quiz]);
    $attempt = attemptApi()->postJson("/api/v1/assessments/{$quiz->id}/attempts")->json('data.id');

    attemptApi()->getJson("/api/v1/attempts/{$attempt}/review")->assertForbidden();
});

it('student cannot touch another student attempt', function () {
    Queue::fake();
    $exam = openExam($this->category);
    $attempt = attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->json('data.id');
    $intruder = User::factory()->student()->create(['level_id' => $this->level->id]);
    app(DeviceService::class)->bind($intruder, ATTEMPT_DEVICE);
    app('auth')->forgetGuards();

    attemptApi($intruder)->postJson("/api/v1/attempts/{$attempt}/submit")->assertNotFound();
    attemptApi($intruder)->getJson("/api/v1/attempts/{$attempt}/result")->assertNotFound();
});

it('answer option must belong to the question', function () {
    Queue::fake();
    $exam = openExam($this->category);
    $attempt = attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->json('data.id');
    [$q1] = correctOption($exam, 0);
    [, $otherOption] = correctOption($exam, 1);

    attemptApi()->putJson("/api/v1/attempts/{$attempt}/answers", ['question_id' => $q1, 'option_id' => $otherOption])
        ->assertStatus(422)->assertJsonValidationErrors('option_id');
});

it('answer question must belong to the attempt', function () {
    Queue::fake();
    $exam = openExam($this->category);
    $attempt = attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->json('data.id');
    $stranger = Question::factory()->withOptions(2)->create(['level_id' => $this->level->id]);

    attemptApi()->putJson("/api/v1/attempts/{$attempt}/answers", ['question_id' => $stranger->id, 'option_id' => $stranger->options()->first()->id])
        ->assertStatus(422)->assertJsonValidationErrors('question_id');
});

it('shuffled attempt keeps the same questions', function () {
    Queue::fake();
    $exam = openExam($this->category, ['shuffle' => true]);

    $ids = collect(attemptApi()->postJson("/api/v1/assessments/{$exam->id}/attempts")->json('data.questions'))->pluck('id')->sort()->values()->all();

    expect($ids)->toBe($exam->questions()->pluck('questions.id')->sort()->values()->all());
});

it('my results paginate with title and kind', function () {
    $quiz = makeAssessment($this->category, ['kind' => AssessmentKind::Quiz, 'title' => 'اختبار قصير']);
    $attempt = attemptApi()->postJson("/api/v1/assessments/{$quiz->id}/attempts")->json('data.id');
    attemptApi()->postJson("/api/v1/attempts/{$attempt}/submit");

    attemptApi()->getJson('/api/v1/me/results')->assertOk()
        ->assertJsonPath('data.0.title', 'اختبار قصير')
        ->assertJsonPath('data.0.kind', 'quiz')
        ->assertJsonPath('meta.per_page', 20);
});

it('homework list shows status per assessment', function () {
    $lecture = Lecture::factory()->for($this->category)->create(['published_at' => now()]);
    $done = makeAssessment($this->category, ['kind' => AssessmentKind::Homework, 'lecture_id' => $lecture->id, 'category_id' => null, 'title' => 'واجب 1']);
    makeAssessment($this->category, ['kind' => AssessmentKind::Homework, 'lecture_id' => $lecture->id, 'category_id' => null, 'title' => 'واجب 2']);
    $attempt = attemptApi()->postJson("/api/v1/assessments/{$done->id}/attempts")->json('data.id');
    attemptApi()->postJson("/api/v1/attempts/{$attempt}/submit");

    $rows = collect(attemptApi()->getJson('/api/v1/me/homework')->assertOk()->json('data'))->keyBy('title');

    expect($rows['واجب 1']['attempt']['status'])->toBe('submitted')
        ->and($rows['واجب 2']['attempt'])->toBeNull()
        ->and($rows['واجب 1']['lecture_id'])->toBe($lecture->id);
});
