<?php

namespace App\Services;

use App\Models\Question;
use App\Support\ImportReport;
use Illuminate\Support\Facades\DB;
use OpenSpout\Reader\XLSX\Reader;

/**
 * Imports MCQ questions from an .xlsx sheet with the columns
 * question | option_1..option_6 | correct (1-6) | explanation | difficulty.
 * Bad rows are reported by spreadsheet row number; the rest are imported.
 */
final class QuestionImportService
{
    private const MAX_OPTIONS = 6;

    private const COL_CORRECT = 7;

    private const COL_EXPLANATION = 8;

    private const COL_DIFFICULTY = 9;

    /**
     * @param  array<int, int>|null  $lectureIds
     */
    public function import(string $path, int $levelId, ?array $lectureIds): ImportReport
    {
        $reader = new Reader;
        $reader->open($path);
        $created = 0;
        $errors = [];

        foreach ($reader->getSheetIterator() as $sheet) {
            foreach ($sheet->getRowIterator() as $number => $row) {
                if ($number === 1) {
                    continue;
                }

                $cells = array_map(fn ($value) => is_string($value) ? trim($value) : $value, $row->toArray());
                $error = $this->problem($cells);

                if ($error !== null) {
                    $errors[$number] = $error;

                    continue;
                }

                $this->create($cells, $levelId, $lectureIds ?? []);
                $created++;
            }

            break;
        }

        $reader->close();

        return new ImportReport($created, $errors);
    }

    /**
     * @param  array<int, mixed>  $cells
     */
    private function problem(array $cells): ?string
    {
        $options = $this->options($cells);
        $correct = $cells[self::COL_CORRECT] ?? null;

        return match (true) {
            ($cells[0] ?? '') === '' => __('import.missing_question'),
            count($options) < 2 => __('import.too_few_options'),
            ! is_numeric($correct) || ! array_key_exists((int) $correct, $options) => __('import.bad_correct'),
            default => null,
        };
    }

    /**
     * Non-empty options keyed by their 1-based column number.
     *
     * @param  array<int, mixed>  $cells
     * @return array<int, string>
     */
    private function options(array $cells): array
    {
        $options = [];

        for ($i = 1; $i <= self::MAX_OPTIONS; $i++) {
            if (($cells[$i] ?? '') !== '' && $cells[$i] !== null) {
                $options[$i] = (string) $cells[$i];
            }
        }

        return $options;
    }

    /**
     * @param  array<int, mixed>  $cells
     * @param  array<int, int>  $lectureIds
     */
    private function create(array $cells, int $levelId, array $lectureIds): void
    {
        DB::transaction(function () use ($cells, $levelId, $lectureIds) {
            $difficulty = $cells[self::COL_DIFFICULTY] ?? null;
            $question = Question::query()->create([
                'text' => (string) $cells[0],
                'explanation' => ($cells[self::COL_EXPLANATION] ?? '') ?: null,
                'difficulty' => is_numeric($difficulty) ? (int) $difficulty : null,
                'level_id' => $levelId,
            ]);

            $correct = (int) $cells[self::COL_CORRECT];
            $position = 0;

            foreach ($this->options($cells) as $column => $text) {
                $question->options()->create(['text' => $text, 'is_correct' => $column === $correct, 'position' => ++$position]);
            }

            $question->lectures()->attach($lectureIds);
        });
    }
}
