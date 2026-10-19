<?php

namespace App\Filament\Pages;

use App\Models\Lecture;
use App\Services\AnalyticsService;
use App\Support\XlsxExport;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Pages\Page;
use Filament\Schemas\Components\EmbeddedTable;
use Filament\Schemas\Schema;
use Filament\Support\ArrayRecord;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;
use Illuminate\Support\Collection;

/**
 * Who watched a lecture and how much, including subscribed students at 0 %.
 */
class LectureReport extends Page implements HasTable
{
    use InteractsWithTable;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedPresentationChartLine;

    public static function getNavigationGroup(): ?string
    {
        return __('panel.reports');
    }

    public static function getNavigationLabel(): string
    {
        return __('panel.lecture_report');
    }

    public function getTitle(): string
    {
        return __('panel.lecture_report');
    }

    public function content(Schema $schema): Schema
    {
        return $schema->components([EmbeddedTable::make()]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->records(fn (?array $filters, ?string $search) => $this->rows($filters, $search)->all())
            ->columns([
                TextColumn::make('student')->label(__('panel.student')),
                TextColumn::make('phone')->label(__('panel.phone'))->copyable(),
                IconColumn::make('subscribed')->label(__('panel.subscribed'))->boolean(),
                TextColumn::make('watched_percent')->label(__('panel.watched'))->suffix('%')->badge()
                    ->color(fn (int $state) => match (true) {
                        $state >= 90 => 'success',
                        $state > 0 => 'warning',
                        default => 'danger',
                    }),
                TextColumn::make('completed_at')->label(__('panel.completed_at'))->placeholder('—'),
            ])
            ->searchable()
            ->filters([
                SelectFilter::make('lecture')->label(__('panel.lecture'))
                    ->options(fn () => Lecture::query()->with('category:id,name')->orderByDesc('id')->limit(200)->get()
                        ->mapWithKeys(fn (Lecture $lecture) => [$lecture->id => "{$lecture->category->name} — {$lecture->title}"])),
                TernaryFilter::make('not_watched')->label(__('panel.not_watched_only')),
            ])
            ->headerActions([
                Action::make('export')
                    ->label(__('panel.export_xlsx'))
                    ->icon('heroicon-o-arrow-down-tray')
                    ->action(fn () => XlsxExport::download('lecture-report.xlsx',
                        [__('panel.student'), __('panel.phone'), __('panel.subscribed'), __('panel.watched'), __('panel.completed_at')],
                        $this->rows($this->tableFilters, $this->getTableSearch())->map(fn (array $row) => [
                            $row['student'], $row['phone'], $row['subscribed'] ? '✓' : '', $row['watched_percent'].'%', $row['completed_at'],
                        ]),
                    )),
            ]);
    }

    /** @return Collection<int, array<string, mixed>> */
    private function rows(?array $filters, ?string $search): Collection
    {
        $lecture = Lecture::query()->find($filters['lecture']['value'] ?? null);

        if ($lecture === null) {
            return collect();
        }

        return app(AnalyticsService::class)->lectureReport($lecture)
            ->when(($filters['not_watched']['value'] ?? null) === '1', fn (Collection $rows) => $rows->where('watched_percent', 0))
            ->when(filled($search), fn (Collection $rows) => $rows->filter(fn (array $row) => str_contains($row['student'].$row['phone'], $search)))
            ->map(fn (array $row) => $row + [ArrayRecord::getKeyName() => $row['student_id']]);
    }
}
