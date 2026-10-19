<?php

namespace App\Filament\Pages;

use App\Jobs\BroadcastNotification;
use App\Models\Category;
use App\Models\Level;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Schemas\Components\Text;
use Filament\Schemas\Components\Utilities\Get;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;

class SendNotification extends Page
{
    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedMegaphone;

    public static function getNavigationLabel(): string
    {
        return __('panel.send_notification');
    }

    public function getTitle(): string
    {
        return __('panel.send_notification');
    }

    public function content(Schema $schema): Schema
    {
        return $schema->components([Text::make(__('panel.send_notification_help'))]);
    }

    protected function getHeaderActions(): array
    {
        return [
            Action::make('send')
                ->label(__('panel.send'))
                ->icon('heroicon-o-paper-airplane')
                ->schema([
                    TextInput::make('title')->label(__('panel.title'))->required()->maxLength(120),
                    Textarea::make('body')->label(__('panel.body'))->required()->maxLength(1000),
                    Select::make('audience')->label(__('panel.audience'))->required()->live()->default('all')
                        ->options(['all' => __('panel.audiences.all'), 'level' => __('panel.audiences.level'), 'category' => __('panel.audiences.category')]),
                    Select::make('level_id')->label(__('panel.level'))
                        ->options(fn () => Level::query()->orderBy('position')->pluck('name', 'id'))
                        ->visible(fn (Get $get) => $get('audience') === 'level')
                        ->required(fn (Get $get) => $get('audience') === 'level'),
                    Select::make('category_id')->label(__('panel.category'))
                        ->options(fn () => Category::query()->with('level:id,name')->get()->mapWithKeys(fn (Category $category) => [$category->id => "{$category->level->name} — {$category->name}"]))
                        ->visible(fn (Get $get) => $get('audience') === 'category')
                        ->required(fn (Get $get) => $get('audience') === 'category'),
                ])
                ->action(function (array $data) {
                    BroadcastNotification::dispatch($data['title'], $data['body'], $data['audience'], match ($data['audience']) {
                        'level' => (int) $data['level_id'],
                        'category' => (int) $data['category_id'],
                        default => null,
                    });

                    Notification::make()->title(__('panel.notification_queued'))->success()->send();
                }),
        ];
    }
}
