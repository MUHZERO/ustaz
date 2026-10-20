<?php

namespace Database\Seeders;

use App\Enums\AssessmentKind;
use App\Enums\SegmentType;
use App\Enums\ShowAnswers;
use App\Models\Announcement;
use App\Models\Assessment;
use App\Models\Category;
use App\Models\Device;
use App\Models\Lecture;
use App\Models\Level;
use App\Models\Paper;
use App\Models\Question;
use App\Models\User;
use App\Services\ActivationCodeService;
use App\Services\AttemptService;
use App\Services\DeviceService;
use App\Services\SubscriptionService;
use App\Services\WatchProgressService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * A small math course for one level: free and paid categories, gated lectures,
 * an open exam and fifty students with progress, attempts and subscriptions.
 * Writes that have a service go through it so the demo obeys the same rules
 * as the app. Run with `php artisan db:seed --class=DemoSeeder`.
 */
class DemoSeeder extends Seeder
{
    private const PDF_PATH = 'demo/lecture-notes.pdf';

    /** Public "Essence of linear algebra" videos (3Blue1Brown): id => duration in seconds. */
    private const VIDEOS = [
        'fNk_zzaMoSs' => 595,
        'k7RM-ot2NWY' => 600,
        'kYB8IZa5AuE' => 659,
        'XkY2DOUCWMU' => 604,
        'Ip3X9LOh2dk' => 600,
        'uQhTuRlWMxw' => 723,
    ];

    private const LECTURES = [
        'أكتوبر' => ['المتجهات', 'التركيب الخطي'],
        'نوفمبر' => ['التحويلات الخطية', 'ضرب المصفوفات'],
        'الترم الأول' => ['المحددات', 'معكوس المصفوفة'],
    ];

    public function __construct(
        private readonly SubscriptionService $subscriptions,
        private readonly ActivationCodeService $codes,
        private readonly WatchProgressService $progress,
        private readonly AttemptService $attempts,
        private readonly DeviceService $devices,
    ) {}

    public function run(): void
    {
        $teacher = User::factory()->teacher()->create(['name' => 'أ. محمد', 'email' => 'teacher@ustaz.test']);
        User::factory()->assistant()->create(['name' => 'المساعد', 'email' => 'assistant@ustaz.test']);

        $level = Level::factory()->create(['name' => 'الصف الثالث الثانوي', 'position' => 1]);
        Level::factory()->create(['name' => 'الصف الثاني الثانوي', 'position' => 2]);

        Storage::disk('local')->put(self::PDF_PATH, $this->pdf());

        $bank = $this->questionBank($level);
        $categories = $this->categories($level);
        $quizzes = $this->lectures($categories, $bank);
        $this->exam($categories['نوفمبر'], $bank);
        Paper::factory()->for($categories['نوفمبر'])->create(['title' => 'ملزمة نوفمبر', 'path' => self::PDF_PATH]);

        Announcement::factory()->create([
            'level_id' => $level->id,
            'title' => 'مرحبًا بكم في كورس الجبر الخطي',
            'body' => 'محاضرات شهر أكتوبر مجانية للجميع.',
            'image_path' => null,
            'published_at' => now(),
        ]);

        $students = $this->students($level);
        $this->subscribe($students, $categories, $teacher);
        $this->watch($students, $categories);
        $this->sitQuizzes($students->take(15), $quizzes->first());
        $this->codes->generate($categories['الترم الأول'], 50, 1, null, now()->addMonths(2));
    }

    /**
     * Forty "a × b" questions, four numeric options each, the product correct.
     *
     * @return Collection<int, Question>
     */
    private function questionBank(Level $level): Collection
    {
        return collect(range(1, 40))->map(function (int $i) use ($level) {
            [$a, $b] = [$i % 9 + 2, intdiv($i, 3) + 3];
            $question = Question::factory()->for($level)->create([
                'text' => "كم يساوي {$a} × {$b}؟",
                'explanation' => "{$a} × {$b} = ".($a * $b),
                'difficulty' => $i % 3 + 1,
            ]);

            $question->options()->createMany(collect([0, 1, -1, $a])->map(fn (int $offset, int $position) => [
                'text' => (string) ($a * $b + $offset),
                'is_correct' => $offset === 0,
                'position' => $position,
            ])->shuffle()->values()->all());

            return $question;
        });
    }

    /** @return array<string, Category> */
    private function categories(Level $level): array
    {
        return collect(array_keys(self::LECTURES))
            ->mapWithKeys(fn (string $name, int $i) => [$name => Category::factory()->for($level)->create([
                'name' => $name,
                'position' => $i + 1,
                'is_free' => $i === 0,
            ])])
            ->all();
    }

    /**
     * Each lecture: video, a gating quiz on five bank questions, then the notes PDF.
     *
     * @param  array<string, Category>  $categories
     * @param  Collection<int, Question>  $bank
     * @return Collection<int, Assessment> the lecture quizzes, in lecture order
     */
    private function lectures(array $categories, Collection $bank): Collection
    {
        $videos = collect(self::VIDEOS)->map(fn (int $seconds, string $id) => [$id, $seconds])->values();
        $quizzes = collect();
        $n = 0;

        foreach (self::LECTURES as $name => $titles) {
            foreach ($titles as $position => $title) {
                [$youtubeId, $seconds] = $videos[$n];
                $lecture = Lecture::factory()->for($categories[$name])->create([
                    'title' => $title,
                    'description' => "شرح {$title} مع أمثلة محلولة.",
                    'position' => $position + 1,
                ]);

                $quiz = Assessment::factory()->create([
                    'kind' => AssessmentKind::Quiz,
                    'title' => "اختبار {$title}",
                    'category_id' => $categories[$name]->id,
                    'lecture_id' => $lecture->id,
                ]);
                $this->attachQuestions($quiz, $bank->slice($n * 5, 5));
                $quizzes->push($quiz);

                $lecture->segments()->createMany([
                    ['type' => SegmentType::Video, 'position' => 1, 'title' => $title, 'youtube_id' => $youtubeId, 'duration_seconds' => $seconds],
                    ['type' => SegmentType::Quiz, 'position' => 2, 'title' => $quiz->title, 'is_gating' => true, 'assessment_id' => $quiz->id, 'pass_percent' => 60],
                    ['type' => SegmentType::Pdf, 'position' => 3, 'title' => 'ملخص المحاضرة', 'pdf_path' => self::PDF_PATH],
                ]);
                $n++;
            }
        }

        return $quizzes;
    }

    /** An exam that is open now for a week: thirty minutes, one attempt, answers after close. */
    private function exam(Category $category, Collection $bank): void
    {
        $exam = Assessment::factory()->create([
            'kind' => AssessmentKind::Exam,
            'title' => "امتحان {$category->name}",
            'category_id' => $category->id,
            'opens_at' => now()->subDay(),
            'closes_at' => now()->addWeek(),
            'duration_minutes' => 30,
            'max_attempts' => 1,
            'shuffle' => true,
            'show_answers' => ShowAnswers::AfterClose,
        ]);

        $this->attachQuestions($exam, $bank->slice(30, 10));
    }

    private function attachQuestions(Assessment $assessment, Collection $questions): void
    {
        $assessment->questions()->attach($questions->values()->mapWithKeys(fn (Question $question, int $i) => [
            $question->id => ['position' => $i + 1, 'mark' => 1],
        ])->all());
    }

    /**
     * Fifty students on one active device each; two of them asked to move to a new phone.
     *
     * @return Collection<int, User>
     */
    private function students(Level $level): Collection
    {
        $first = ['أحمد', 'محمد', 'يوسف', 'عمر', 'مريم', 'سارة', 'نور', 'خالد', 'ليلى', 'آدم'];
        $last = ['حسن', 'إبراهيم', 'عبد الله', 'سليمان', 'مصطفى'];
        $students = User::factory()->student()->count(50)->has(Device::factory())
            ->sequence(fn ($sequence) => ['name' => $first[$sequence->index % 10].' '.$last[intdiv($sequence->index, 10)]])
            ->create(['level_id' => $level->id]);

        $students->take(2)->each(fn (User $student) => $this->devices->bind($student, (string) Str::uuid()));

        return $students;
    }

    /** @param  array<string, Category>  $categories */
    private function subscribe(Collection $students, array $categories, User $teacher): void
    {
        $students->take(30)->each(fn (User $student) => $this->subscriptions->grant($student, $categories['نوفمبر'], null, $teacher, null));
        $students->take(10)->each(fn (User $student) => $this->subscriptions->grant($student, $categories['الترم الأول'], now()->addMonths(3), $teacher, null));
    }

    /**
     * The first 25 students watched the free first video (even ones to the end);
     * subscribed ones also started November.
     *
     * @param  array<string, Category>  $categories
     */
    private function watch(Collection $students, array $categories): void
    {
        $free = $this->firstVideo($categories['أكتوبر']);
        $paid = $this->firstVideo($categories['نوفمبر']);

        $students->take(25)->each(function (User $student, int $i) use ($free, $paid) {
            $watched = $i % 2 === 0 ? $free['duration_seconds'] : intdiv($free['duration_seconds'], 3);
            $this->progress->record($student, $free['id'], $watched, $watched, $free['duration_seconds']);
            $this->progress->record($student, $paid['id'], 120, 120, $paid['duration_seconds']);
        });
    }

    /** @return array{id: int, duration_seconds: int} */
    private function firstVideo(Category $category): array
    {
        return $category->lectures()->orderBy('position')->firstOrFail()
            ->segments()->where('type', SegmentType::Video)->firstOrFail()
            ->only(['id', 'duration_seconds']);
    }

    /** Students answer through the attempt service; every third one gets one answer wrong. */
    private function sitQuizzes(Collection $students, Assessment $quiz): void
    {
        $students->each(function (User $student, int $i) use ($quiz) {
            [$attempt] = $this->attempts->start($student, $quiz);

            foreach ($attempt->answers()->get() as $n => $answer) {
                $options = collect($answer->snapshot['options'])->pluck('id');
                $correct = $answer->snapshot['correct_option_id'];
                $chosen = $i % 3 === 0 && $n === 0 ? $options->first(fn (int $id) => $id !== $correct) : $correct;
                $this->attempts->answer($attempt, $answer->question_id, $chosen);
            }

            $this->attempts->submit($attempt);
        });
    }

    /** A one-page PDF built by hand, so the demo needs no PDF library or binary fixture. */
    private function pdf(): string
    {
        $text = 'BT /F1 24 Tf 72 760 Td (Ustaz demo lecture notes) Tj ET';
        $objects = [
            '<< /Type /Catalog /Pages 2 0 R >>',
            '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
            '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>',
            '<< /Length '.strlen($text)." >>\nstream\n{$text}\nendstream",
            '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
        ];

        $pdf = "%PDF-1.4\n";
        $xref = '';

        foreach ($objects as $i => $object) {
            $xref .= sprintf("%010d 00000 n \n", strlen($pdf));
            $pdf .= ($i + 1)." 0 obj\n{$object}\nendobj\n";
        }

        $size = count($objects) + 1;

        return $pdf."xref\n0 {$size}\n0000000000 65535 f \n{$xref}trailer << /Size {$size} /Root 1 0 R >>\nstartxref\n".strlen($pdf)."\n%%EOF\n";
    }
}
