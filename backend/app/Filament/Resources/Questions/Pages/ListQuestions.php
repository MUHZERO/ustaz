<?php

namespace App\Filament\Resources\Questions\Pages;

use App\Filament\Resources\Questions\QuestionResource;
use App\Models\Lecture;
use App\Models\Level;
use App\Services\QuestionImportService;
use Filament\Actions\Action;
use Filament\Actions\CreateAction;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ListRecords;
use Illuminate\Support\Facades\Storage;

class ListQuestions extends ListRecords
{
    protected static string $resource = QuestionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
            Action::make('import')
                ->label(__('panel.import_questions'))
                ->icon('heroicon-o-arrow-up-tray')
                ->authorize('create')
                ->schema([
                    FileUpload::make('file')
                        ->label(__('panel.xlsx_file'))
                        ->disk('local')
                        ->directory('imports')
                        ->acceptedFileTypes(['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'])
                        ->maxSize(5120)
                        ->required(),
                    Select::make('level_id')->label(__('panel.level'))->options(fn () => Level::query()->pluck('name', 'id'))->required(),
                    Select::make('lecture_ids')->label(__('panel.lectures'))->multiple()->options(fn () => Lecture::query()->pluck('title', 'id')),
                ])
                ->action(function (array $data, QuestionImportService $import) {
                    $path = Storage::disk('local')->path($data['file']);
                    $report = $import->import($path, (int) $data['level_id'], $data['lecture_ids'] ?? null);
                    Storage::disk('local')->delete($data['file']);

                    Notification::make()
                        ->title(__('panel.import_done', ['count' => $report->created]))
                        ->body(collect($report->errors)->map(fn ($error, $row) => __('panel.import_row_error', ['row' => $row, 'error' => $error]))->implode("\n") ?: null)
                        ->status($report->errors === [] ? 'success' : 'warning')
                        ->send();
                }),
        ];
    }
}
