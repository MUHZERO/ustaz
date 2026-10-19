<?php

use App\Models\Lecture;
use App\Models\Level;
use App\Models\Question;
use App\Services\QuestionImportService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use OpenSpout\Common\Entity\Row;
use OpenSpout\Writer\XLSX\Writer;

uses(RefreshDatabase::class);

function questionsSheet(array $rows): string
{
    $path = tempnam(sys_get_temp_dir(), 'questions').'.xlsx';
    $writer = new Writer;
    $writer->openToFile($path);
    $writer->addRow(Row::fromValues(['question', 'option_1', 'option_2', 'option_3', 'option_4', 'option_5', 'option_6', 'correct', 'explanation', 'difficulty']));
    foreach ($rows as $row) {
        $writer->addRow(Row::fromValues($row));
    }
    $writer->close();

    return $path;
}

it('imports valid rows with options and correct answer', function () {
    $level = Level::factory()->create();
    $lecture = Lecture::factory()->create();
    $path = questionsSheet([
        ['ما ناتج 2 + 2؟', '3', '4', '5', '', '', '', 2, 'جمع بسيط', 1],
        ['ما ناتج 3 × 3؟', '6', '9', '', '', '', '', 2, '', 2],
    ]);

    $report = app(QuestionImportService::class)->import($path, $level->id, [$lecture->id]);

    expect($report->created)->toBe(2)->and($report->errors)->toBe([]);
    $question = Question::query()->with('options', 'lectures')->where('text', 'ما ناتج 2 + 2؟')->firstOrFail();
    expect($question->options->pluck('text')->all())->toBe(['3', '4', '5'])
        ->and($question->options->firstWhere('is_correct', true)->text)->toBe('4')
        ->and($question->explanation)->toBe('جمع بسيط')
        ->and($question->difficulty)->toBe(1)
        ->and($question->level_id)->toBe($level->id)
        ->and($question->lectures->pluck('id')->all())->toBe([$lecture->id]);
});

it('reports row with missing correct column', function () {
    $level = Level::factory()->create();
    $path = questionsSheet([
        ['سؤال صحيح', 'أ', 'ب', '', '', '', '', 1, '', ''],
        ['سؤال بلا إجابة', 'أ', 'ب', '', '', '', '', '', '', ''],
        ['إجابة خارج الخيارات', 'أ', 'ب', '', '', '', '', 5, '', ''],
        ['خيار واحد فقط', 'أ', '', '', '', '', '', 1, '', ''],
    ]);

    $report = app(QuestionImportService::class)->import($path, $level->id, null);

    expect($report->created)->toBe(1)
        ->and(array_keys($report->errors))->toBe([3, 4, 5])
        ->and(Question::count())->toBe(1);
});

it('keeps arabic text intact', function () {
    $level = Level::factory()->create();
    $text = 'إذا كانت س = ٣ فما قيمة ٢س؟';
    $path = questionsSheet([[$text, '٥', '٦', '', '', '', '', 2, '', '']]);

    app(QuestionImportService::class)->import($path, $level->id, null);

    expect(Question::first()->text)->toBe($text)
        ->and(Question::first()->options()->orderBy('position')->pluck('text')->all())->toBe(['٥', '٦']);
});
