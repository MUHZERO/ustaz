<?php

namespace App\Filament\Pages;

use App\Enums\AssessmentKind;
use App\Models\Assessment;
use App\Models\Question;
use App\Models\User;
use App\Services\AnalyticsService;
use App\Support\XlsxExport;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Pages\Page;
use Filament\Schemas\Components\EmbeddedTable;
use Filament\Schemas\Schema;
use Filament\Support\ArrayRecord;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Support\HtmlString;

/**
 * Each subscribed student's best result in an exam, absent students included,
 * with the average and the questions most students got wrong.
 */
class ExamReport extends Page implements HasTable
{
    use InteractsWithTable;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedChartBar;

    /** @var array<string, mixed>|null */
    private ?array $report = null;

    public static function getNavigationGroup(): ?string
    {
        return __('panel.reports');
    }

    public static function getNavigationLabel(): string
    {
        return __('panel.exam_report');
    }

    public function getTitle(): string
    {
        return __('panel.exam_report');
    }

    public function getSubheading(): ?string
    {
        $report = $this->report();

        return $report === null ? __('panel.choose_exam') : __('panel.exam_summary', [
            'average' => $report['average'] ?? '—',
            'submitted' => $report['percents']->count(),
            'absent' => $report['absent']->count(),
        ]);
    }

    public function content(Schema $schema): Schema
    {
        return $schema->components([EmbeddedTable::make()]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->records(fn () => $this->rows())
            ->columns([
                TextColumn::make('student')->label(__('panel.student')),
                TextColumn::make('phone')->label(__('panel.phone'))->copyable(),
                TextColumn::make('parent_phone')->label(__('panel.parent_phone'))->copyable(),
                TextColumn::make('percent')->label(__('panel.score'))->badge()
                    ->formatStateUsing(fn (float $state) => round($state, 1).'%')
                    ->color(fn (float $state) => $state >= 50 ? 'success' : 'danger')
                    ->placeholder(__('panel.absent')),
            ])
            ->filters([
                SelectFilter::make('exam')->label(__('panel.exam'))
                    ->options(fn () => Assessment::query()->where('kind', AssessmentKind::Exam)->orderByDesc('id')->limit(200)->pluck('title', 'id')),
            ])
            ->headerActions([
                Action::make('hardest')
                    ->label(__('panel.hardest_questions'))
                    ->icon('heroicon-o-exclamation-triangle')
                    ->visible(fn () => $this->report() !== null)
                    ->modalSubmitAction(false)
                    ->modalContent(fn () => $this->hardestQuestions()),
                Action::make('export')
                    ->label(__('panel.export_xlsx'))
                    ->icon('heroicon-o-arrow-down-tray')
                    ->visible(fn () => $this->report() !== null)
                    ->action(fn () => XlsxExport::download('exam-report.xlsx',
                        [__('panel.student'), __('panel.phone'), __('panel.parent_phone'), __('panel.score')],
                        array_map(fn (array $row) => [
                            $row['student'], $row['phone'], $row['parent_phone'], $row['percent'] === null ? __('panel.absent') : round($row['percent'], 1),
                        ], $this->rows()),
                    )),
            ]);
    }

    /** @return array<string, mixed>|null */
    private function report(): ?array
    {
        $exam = Assessment::query()->find($this->tableFilters['exam']['value'] ?? null);

        if ($exam === null) {
            return null;
        }

        return $this->report ??= app(AnalyticsService::class)->examReport($exam);
    }

    /** @return array<int, array<string, mixed>> */
    private function rows(): array
    {
        $report = $this->report();

        if ($report === null) {
            return [];
        }

        $submitted = User::query()->whereIn('id', $report['percents']->keys())->get(['id', 'name', 'phone', 'parent_phone']);

        return $submitted->concat($report['absent'])
            ->map(fn (User $student) => [
                ArrayRecord::getKeyName() => $student->id,
                'student' => $student->name,
                'phone' => $student->phone,
                'parent_phone' => $student->parent_phone,
                'percent' => $report['percents'][$student->id] ?? null,
            ])
            ->sortByDesc('percent')
            ->values()
            ->all();
    }

    private function hardestQuestions(): HtmlString
    {
        $rates = collect($this->report()['error_rates'] ?? [])->sortDesc()->take(10);
        $texts = Question::query()->whereIn('id', $rates->keys())->pluck('text', 'id');

        return new HtmlString('<ol class="list-decimal ps-6 space-y-2">'.$rates->map(fn (float $rate, int $id) => '<li>'.e($texts[$id] ?? "#{$id}").' — <strong>'.e(__('panel.wrong_percent', ['percent' => $rate])).'</strong></li>')->implode('').'</ol>');
    }
}
