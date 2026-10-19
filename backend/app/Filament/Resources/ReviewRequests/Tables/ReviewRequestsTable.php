<?php

namespace App\Filament\Resources\ReviewRequests\Tables;

use App\Enums\ReviewStatus;
use App\Models\ReviewRequest;
use App\Services\ReviewService;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class ReviewRequestsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query) => $query->with(['attempt:id,user_id,assessment_id,score,max_score', 'attempt.user:id,name,phone', 'attempt.assessment:id,title']))
            ->defaultSort('id', 'desc')
            ->columns([
                TextColumn::make('attempt.user.name')->label(__('panel.student'))->description(fn (ReviewRequest $record) => $record->attempt->user->phone),
                TextColumn::make('attempt.assessment.title')->label(__('panel.exam')),
                TextColumn::make('attempt.score')->label(__('panel.score'))
                    ->formatStateUsing(fn (ReviewRequest $record) => "{$record->attempt->score} / {$record->attempt->max_score}"),
                TextColumn::make('note')->label(__('panel.student_note'))->wrap()->limit(120),
                TextColumn::make('status')->label(__('panel.status'))->badge()
                    ->formatStateUsing(fn (ReviewStatus $state) => __('panel.statuses.'.$state->value))
                    ->color(fn (ReviewStatus $state) => match ($state) {
                        ReviewStatus::Pending => 'warning',
                        ReviewStatus::Accepted => 'success',
                        ReviewStatus::Rejected => 'danger',
                    }),
                TextColumn::make('created_at')->label(__('panel.created_at'))->since(),
            ])
            ->filters([
                SelectFilter::make('status')->label(__('panel.status'))
                    ->options(collect(ReviewStatus::cases())->mapWithKeys(fn (ReviewStatus $status) => [$status->value => __('panel.statuses.'.$status->value)]))
                    ->default(ReviewStatus::Pending->value),
            ])
            ->recordActions([
                Action::make('decide')
                    ->label(__('panel.decide'))
                    ->icon('heroicon-o-check-badge')
                    ->authorize('update')
                    ->visible(fn (ReviewRequest $record) => $record->status === ReviewStatus::Pending)
                    ->schema([
                        Select::make('status')->label(__('panel.decision'))->required()->options([
                            ReviewStatus::Accepted->value => __('panel.statuses.accepted'),
                            ReviewStatus::Rejected->value => __('panel.statuses.rejected'),
                        ]),
                        Textarea::make('reply')->label(__('panel.reply'))->helperText(__('panel.reply_help'))->maxLength(1000),
                    ])
                    ->action(fn (ReviewRequest $record, array $data, ReviewService $reviews) => $reviews->decide(
                        $record, ReviewStatus::from($data['status']), $data['reply'] ?? null, auth()->user(),
                    )),
            ]);
    }
}
