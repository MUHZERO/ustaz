<?php

namespace App\Filament\Resources\Assessments\Schemas;

use App\Enums\AssessmentKind;
use App\Enums\ShowAnswers;
use App\Models\Question;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Utilities\Get;
use Filament\Schemas\Schema;

class AssessmentForm
{
    public static function configure(Schema $schema): Schema
    {
        $isExam = fn (Get $get) => $get('kind') === AssessmentKind::Exam->value;

        return $schema
            ->components([
                Select::make('kind')
                    ->label(__('panel.kind'))
                    ->options(collect(AssessmentKind::cases())->mapWithKeys(fn (AssessmentKind $kind) => [$kind->value => __("panel.kinds.{$kind->value}")]))
                    ->required()
                    ->live(),
                TextInput::make('title')->label(__('panel.title'))->required()->maxLength(255),
                Select::make('category_id')->label(__('panel.category'))->relationship('category', 'name')->preload()->required($isExam),
                Select::make('lecture_id')->label(__('panel.lecture'))->relationship('lecture', 'title')->searchable()->preload()->hidden($isExam),
                DateTimePicker::make('opens_at')->label(__('panel.opens_at'))->visible($isExam)->required($isExam),
                DateTimePicker::make('closes_at')->label(__('panel.closes_at'))->visible($isExam)->required($isExam)->after('opens_at'),
                TextInput::make('duration_minutes')->label(__('panel.duration_minutes'))->integer()->minValue(1)->maxValue(600),
                TextInput::make('max_attempts')->label(__('panel.max_attempts'))->integer()->minValue(1)->helperText(__('panel.max_attempts_help')),
                Toggle::make('shuffle')->label(__('panel.shuffle'))->default(false),
                Select::make('show_answers')
                    ->label(__('panel.show_answers'))
                    ->options(collect(ShowAnswers::cases())->mapWithKeys(fn (ShowAnswers $case) => [$case->value => __("panel.show_answers_options.{$case->value}")]))
                    ->default(ShowAnswers::AfterSubmit->value)
                    ->required(),
                Toggle::make('is_free')->label(__('panel.is_free'))->default(false),
                Select::make('questions')
                    ->label(__('panel.questions'))
                    ->helperText(__('panel.questions_help'))
                    ->multiple()
                    ->searchable()
                    ->options(fn () => Question::query()->whereNull('archived_at')->latest('id')->limit(500)->pluck('text', 'id'))
                    ->getSearchResultsUsing(fn (string $search) => Question::query()->whereNull('archived_at')->where('text', 'like', "%{$search}%")->limit(50)->pluck('text', 'id'))
                    ->required()
                    ->columnSpanFull()
                    ->afterStateHydrated(fn (Select $component, $record) => $component->state($record?->questions()->pluck('questions.id')->all() ?? []))
                    ->dehydrated(false)
                    ->saveRelationshipsUsing(function ($record, ?array $state) {
                        // The order picked in the form is the order students see; existing marks are kept.
                        $marks = $record->questions()->pluck('assessment_question.mark', 'questions.id');
                        $record->questions()->sync(collect($state ?? [])->values()->mapWithKeys(fn ($id, $i) => [
                            (int) $id => ['position' => $i + 1, 'mark' => $marks[(int) $id] ?? 1],
                        ])->all());
                    }),
            ]);
    }
}
