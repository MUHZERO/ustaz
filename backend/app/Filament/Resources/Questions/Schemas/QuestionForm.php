<?php

namespace App\Filament\Resources\Questions\Schemas;

use Closure;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class QuestionForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('level_id')->label(__('panel.level'))->relationship('level', 'name')->preload()->required(),
                Textarea::make('text')->label(__('panel.question_text'))->requiredWithout('image_path')->columnSpanFull(),
                FileUpload::make('image_path')->label(__('panel.image'))->image()->disk('public')->directory('questions')->maxSize(2048),
                Select::make('difficulty')->label(__('panel.difficulty'))->options([1 => '1', 2 => '2', 3 => '3']),
                Select::make('lectures')->label(__('panel.lectures'))->relationship('lectures', 'title')->multiple()->searchable()->preload(),
                Textarea::make('explanation')->label(__('panel.explanation'))->columnSpanFull(),
                Repeater::make('options')
                    ->label(__('panel.options'))
                    ->relationship()
                    ->orderColumn('position')
                    ->minItems(2)
                    ->maxItems(6)
                    ->defaultItems(4)
                    ->columnSpanFull()
                    ->rule(fn (): Closure => function (string $attribute, mixed $value, Closure $fail) {
                        if (collect($value)->where('is_correct', true)->count() !== 1) {
                            $fail(__('panel.exactly_one_correct'));
                        }
                    })
                    ->schema([
                        TextInput::make('text')->label(__('panel.option_text'))->required()->maxLength(500),
                        Toggle::make('is_correct')->label(__('panel.is_correct'))->default(false),
                    ]),
            ]);
    }
}
