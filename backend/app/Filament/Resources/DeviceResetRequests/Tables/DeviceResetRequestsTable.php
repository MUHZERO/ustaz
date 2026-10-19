<?php

namespace App\Filament\Resources\DeviceResetRequests\Tables;

use App\Enums\ReviewStatus;
use App\Models\DeviceResetRequest;
use App\Services\DeviceService;
use Filament\Actions\Action;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class DeviceResetRequestsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('id', 'desc')
            ->columns([
                TextColumn::make('user.name')->label(__('panel.student'))->searchable(),
                TextColumn::make('user.phone')->label(__('panel.phone'))->searchable(),
                TextColumn::make('device_uuid')->label(__('panel.device'))->limit(13)->fontFamily('mono'),
                TextColumn::make('status')->label(__('panel.status'))->badge()
                    ->formatStateUsing(fn (ReviewStatus $state) => __('panel.statuses.'.$state->value)),
                TextColumn::make('created_at')->label(__('panel.created_at'))->since(),
            ])
            ->filters([
                SelectFilter::make('status')->label(__('panel.status'))
                    ->options(collect(ReviewStatus::cases())->mapWithKeys(fn (ReviewStatus $status) => [$status->value => __('panel.statuses.'.$status->value)]))
                    ->default(ReviewStatus::Pending->value),
            ])
            ->recordActions([
                Action::make('approve')
                    ->label(__('panel.approve_device'))
                    ->icon('heroicon-o-check')
                    ->color('success')
                    ->requiresConfirmation()
                    ->modalDescription(__('panel.approve_device_help'))
                    ->authorize('update')
                    ->visible(fn (DeviceResetRequest $record) => $record->status === ReviewStatus::Pending)
                    ->action(fn (DeviceResetRequest $record, DeviceService $devices) => $devices->approve($record, auth()->user())),
                Action::make('reject')
                    ->label(__('panel.reject'))
                    ->icon('heroicon-o-x-mark')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->authorize('update')
                    ->visible(fn (DeviceResetRequest $record) => $record->status === ReviewStatus::Pending)
                    ->action(fn (DeviceResetRequest $record) => $record->update(['status' => ReviewStatus::Rejected, 'handled_by' => auth()->id()])),
            ]);
    }
}
