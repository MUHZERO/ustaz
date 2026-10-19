<?php

namespace App\Filament\Resources\Lectures\Schemas;

use App\Enums\AssessmentKind;
use App\Enums\SegmentType;
use App\Models\Assessment;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Utilities\Get;
use Filament\Schemas\Schema;

class LectureForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('category_id')
                    ->label(__('panel.category'))
                    ->relationship('category', 'name')
                    ->searchable()
                    ->preload()
                    ->required(),
                TextInput::make('title')->label(__('panel.title'))->required()->maxLength(255),
                Textarea::make('description')->label(__('panel.description'))->columnSpanFull(),
                TextInput::make('position')->label(__('panel.position'))->required()->integer()->minValue(0)->default(0),
                Toggle::make('is_free')->label(__('panel.is_free'))->default(false),
                FileUpload::make('thumbnail_path')->label(__('panel.thumbnail'))->image()->disk('public')->directory('thumbnails')->maxSize(2048),
                DateTimePicker::make('published_at')->label(__('panel.published_at'))->helperText(__('panel.published_at_help')),
                self::segments(),
            ]);
    }

    private static function segments(): Repeater
    {
        $is = fn (SegmentType $type) => fn (Get $get) => $get('type') === $type->value;

        return Repeater::make('segments')
            ->label(__('panel.segments'))
            ->relationship()
            ->orderColumn('position')
            ->columnSpanFull()
            ->itemLabel(fn (array $state) => $state['title'] ?? null)
            ->schema([
                Select::make('type')
                    ->label(__('panel.segment_type'))
                    ->options(collect(SegmentType::cases())->mapWithKeys(fn (SegmentType $type) => [$type->value => __("panel.segment_types.{$type->value}")]))
                    ->required()
                    ->live(),
                TextInput::make('title')->label(__('panel.title'))->required()->maxLength(255),
                TextInput::make('youtube_id')
                    ->label(__('panel.youtube_id'))
                    ->helperText(__('panel.youtube_id_help'))
                    ->regex('/^[A-Za-z0-9_-]{11}$/')
                    ->visible($is(SegmentType::Video))
                    ->required($is(SegmentType::Video)),
                TextInput::make('duration_seconds')
                    ->label(__('panel.duration_seconds'))
                    ->integer()
                    ->minValue(1)
                    ->visible($is(SegmentType::Video))
                    ->required($is(SegmentType::Video)),
                FileUpload::make('pdf_path')
                    ->label(__('panel.pdf'))
                    ->disk('local')
                    ->directory('papers')
                    ->acceptedFileTypes(['application/pdf'])
                    ->maxSize(20480)
                    ->visible($is(SegmentType::Pdf))
                    ->required($is(SegmentType::Pdf)),
                Select::make('assessment_id')
                    ->label(__('panel.quiz'))
                    ->options(fn () => Assessment::query()->whereIn('kind', [AssessmentKind::Quiz, AssessmentKind::Homework])->pluck('title', 'id'))
                    ->searchable()
                    ->visible($is(SegmentType::Quiz))
                    ->required($is(SegmentType::Quiz)),
                Toggle::make('is_gating')->label(__('panel.is_gating'))->helperText(__('panel.is_gating_help'))->visible($is(SegmentType::Quiz))->live(),
                TextInput::make('pass_percent')
                    ->label(__('panel.pass_percent'))
                    ->integer()
                    ->minValue(1)
                    ->maxValue(100)
                    ->visible(fn (Get $get) => $get('type') === SegmentType::Quiz->value && $get('is_gating'))
                    ->required(fn (Get $get) => (bool) $get('is_gating')),
            ]);
    }
}
