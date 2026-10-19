<?php

use App\Enums\AssessmentKind;
use App\Enums\SegmentType;
use App\Filament\Resources\Assessments\Pages\CreateAssessment;
use App\Filament\Resources\Lectures\LectureResource;
use App\Filament\Resources\Lectures\Pages\CreateLecture;
use App\Filament\Resources\Lectures\Pages\ListLectures;
use App\Filament\Resources\Questions\Pages\CreateQuestion;
use App\Filament\Resources\Questions\Pages\ListQuestions;
use App\Models\Assessment;
use App\Models\Category;
use App\Models\Lecture;
use App\Models\Level;
use App\Models\Question;
use App\Models\User;
use Filament\Forms\Components\Repeater;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use OpenSpout\Common\Entity\Row;
use OpenSpout\Writer\XLSX\Writer;

use function Pest\Livewire\livewire;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->level = Level::factory()->create();
    $this->category = Category::factory()->for($this->level)->create();
    $this->teacher = User::factory()->teacher()->create();
});

it('student cannot access panel', function () {
    $this->actingAs(User::factory()->student()->create())->get('/admin')->assertForbidden();
});

it('teacher and assistant can access panel', function () {
    $this->actingAs($this->teacher)->get('/admin')->assertOk();
    $this->actingAs(User::factory()->assistant()->create())->get('/admin')->assertOk();
});

it('teacher can create lecture with ordered segments', function () {
    Repeater::fake();
    $quiz = Assessment::factory()->create(['kind' => AssessmentKind::Quiz, 'category_id' => $this->category->id]);
    $this->actingAs($this->teacher);

    livewire(CreateLecture::class)
        ->fillForm([
            'category_id' => $this->category->id,
            'title' => 'الدرس الأول',
            'position' => 1,
            'is_free' => false,
            'published_at' => now(),
            'segments' => [
                ['type' => SegmentType::Quiz->value, 'title' => 'اختبار قبلي', 'assessment_id' => $quiz->id, 'is_gating' => true, 'pass_percent' => 60],
                ['type' => SegmentType::Video->value, 'title' => 'الشرح', 'youtube_id' => 'dQw4w9WgXcQ', 'duration_seconds' => 900, 'is_gating' => false],
            ],
        ])
        ->call('create')
        ->assertHasNoFormErrors();

    $lecture = Lecture::query()->with('segments')->firstOrFail();
    expect($lecture->segments->pluck('type')->all())->toBe([SegmentType::Quiz, SegmentType::Video])
        ->and($lecture->segments->pluck('position')->all())->toBe([1, 2])
        ->and($lecture->segments->first()->assessment_id)->toBe($quiz->id);
});

it('video segment requires a youtube id', function () {
    Repeater::fake();
    $this->actingAs($this->teacher);

    livewire(CreateLecture::class)
        ->fillForm([
            'category_id' => $this->category->id,
            'title' => 'درس',
            'position' => 1,
            'segments' => [['type' => SegmentType::Video->value, 'title' => 'فيديو', 'youtube_id' => null, 'duration_seconds' => 60]],
        ])
        ->call('create')
        ->assertHasFormErrors();
});

it('assistant can list but cannot edit lectures', function () {
    $lecture = Lecture::factory()->for($this->category)->create();
    $this->actingAs(User::factory()->assistant()->create());

    livewire(ListLectures::class)->assertOk()->assertCanSeeTableRecords([$lecture]);
    $this->get(LectureResource::getUrl('edit', ['record' => $lecture]))->assertForbidden();
});

it('question requires exactly one correct option', function () {
    Repeater::fake();
    $this->actingAs($this->teacher);
    $base = ['text' => 'ما ناتج 2+2؟', 'level_id' => $this->level->id];

    livewire(CreateQuestion::class)
        ->fillForm($base + ['options' => [['text' => '3', 'is_correct' => true], ['text' => '4', 'is_correct' => true]]])
        ->call('create')
        ->assertHasFormErrors(['options']);

    livewire(CreateQuestion::class)
        ->fillForm($base + ['options' => [['text' => '3', 'is_correct' => false], ['text' => '4', 'is_correct' => true]]])
        ->call('create')
        ->assertHasNoFormErrors();

    expect(Question::query()->with('options')->firstOrFail()->options->pluck('position')->all())->toBe([1, 2]);
});

it('assessment keeps the chosen question order', function () {
    $this->actingAs($this->teacher);
    $questions = Question::factory()->count(3)->withOptions(2)->create(['level_id' => $this->level->id]);
    $order = [$questions[2]->id, $questions[0]->id, $questions[1]->id];

    livewire(CreateAssessment::class)
        ->fillForm([
            'kind' => AssessmentKind::Exam->value,
            'title' => 'امتحان أكتوبر',
            'category_id' => $this->category->id,
            'opens_at' => now(),
            'closes_at' => now()->addDay(),
            'duration_minutes' => 30,
            'show_answers' => 'after_close',
            'questions' => $order,
        ])
        ->call('create')
        ->assertHasNoFormErrors();

    expect(Assessment::query()->firstOrFail()->questions()->pluck('questions.id')->all())->toBe($order);
});

it('import action reports created count', function () {
    $this->actingAs($this->teacher);
    $path = tempnam(sys_get_temp_dir(), 'q').'.xlsx';
    $writer = new Writer;
    $writer->openToFile($path);
    $writer->addRow(Row::fromValues(['question', 'option_1', 'option_2', 'option_3', 'option_4', 'option_5', 'option_6', 'correct', 'explanation', 'difficulty']));
    $writer->addRow(Row::fromValues(['سؤال', 'أ', 'ب', '', '', '', '', 1, '', '']));
    $writer->close();

    livewire(ListQuestions::class)
        ->callAction('import', data: [
            'file' => UploadedFile::fake()->createWithContent('questions.xlsx', file_get_contents($path)),
            'level_id' => $this->level->id,
        ])
        ->assertHasNoActionErrors()
        ->assertNotified();

    expect(Question::count())->toBe(1);
});
