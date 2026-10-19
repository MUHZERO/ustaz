<?php

namespace App\Filament\Resources\ActivationCodes\Pages;

use App\Filament\Resources\ActivationCodes\ActivationCodeResource;
use App\Models\Category;
use App\Services\ActivationCodeService;
use Filament\Actions\Action;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ListRecords;
use Illuminate\Support\Carbon;

class ListActivationCodes extends ListRecords
{
    protected static string $resource = ActivationCodeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Action::make('generate')
                ->label(__('panel.generate_codes'))
                ->icon('heroicon-o-sparkles')
                ->authorize('create')
                ->schema([
                    Select::make('category_id')->label(__('panel.category'))
                        ->options(fn () => Category::query()->with('level:id,name')->get()->mapWithKeys(fn (Category $category) => [$category->id => "{$category->level->name} — {$category->name}"]))
                        ->required(),
                    TextInput::make('count')->label(__('panel.count'))->integer()->minValue(1)->maxValue(5000)->default(100)->required(),
                    TextInput::make('max_uses')->label(__('panel.max_uses'))->integer()->minValue(1)->maxValue(1000)->default(1)->required(),
                    DatePicker::make('ends_at')->label(__('panel.access_ends_at'))->helperText(__('panel.access_ends_at_help'))->afterOrEqual('today'),
                    DatePicker::make('expires_at')->label(__('panel.code_expires_at'))->afterOrEqual('today'),
                ])
                ->action(function (array $data, ActivationCodeService $codes) {
                    $batch = $codes->generate(
                        Category::query()->findOrFail($data['category_id']),
                        (int) $data['count'],
                        (int) $data['max_uses'],
                        $data['ends_at'] ? Carbon::parse($data['ends_at'])->endOfDay() : null,
                        $data['expires_at'] ? Carbon::parse($data['expires_at'])->endOfDay() : null,
                    );

                    Notification::make()
                        ->title(__('panel.codes_generated', ['count' => $data['count']]))
                        ->success()
                        ->actions([Action::make('print')->label(__('panel.print_batch'))->url(route('codes.print', $batch), shouldOpenInNewTab: true)])
                        ->send();
                }),
        ];
    }
}
