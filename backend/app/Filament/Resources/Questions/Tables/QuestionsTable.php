<?php

namespace App\Filament\Resources\Questions\Tables;

use App\Models\AttemptAnswer;
use App\Models\Question;
use Filament\Actions\Action;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;

class QuestionsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('text')->label(__('panel.question_text'))->limit(80)->searchable()->wrap(),
                TextColumn::make('level.name')->label(__('panel.level'))->sortable(),
                TextColumn::make('difficulty')->label(__('panel.difficulty'))->sortable(),
                TextColumn::make('options_count')->label(__('panel.options'))->counts('options'),
                TextColumn::make('archived_at')->label(__('panel.archived_at'))->dateTime()->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('level_id')->label(__('panel.level'))->relationship('level', 'name'),
                TernaryFilter::make('archived_at')->label(__('panel.archived'))->nullable()->default(false),
            ])
            ->recordActions([
                EditAction::make(),
                // Questions already answered keep their history: they are archived, not deleted.
                Action::make('archive')
                    ->label(__('panel.archive'))
                    ->icon('heroicon-o-archive-box')
                    ->requiresConfirmation()
                    ->authorize('update')
                    ->visible(fn (Question $record) => $record->archived_at === null)
                    ->action(fn (Question $record) => $record->update(['archived_at' => now()])),
                DeleteAction::make()->visible(fn (Question $record) => ! AttemptAnswer::query()->where('question_id', $record->id)->exists()),
            ]);
    }
}
