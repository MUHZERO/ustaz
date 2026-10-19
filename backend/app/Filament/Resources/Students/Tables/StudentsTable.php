<?php

namespace App\Filament\Resources\Students\Tables;

use App\Enums\ReviewStatus;
use App\Models\Category;
use App\Models\User;
use App\Services\AuthService;
use App\Services\DeviceService;
use App\Services\SubscriptionService;
use App\Support\XlsxExport;
use Filament\Actions\Action;
use Filament\Actions\ActionGroup;
use Filament\Actions\BulkAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Carbon;

class StudentsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query) => $query
                ->with('level:id,name')
                ->withCount(['subscriptions' => fn (Builder $subscription) => $subscription->active()])
                ->withExists(['deviceResetRequests as has_pending_device' => fn (Builder $request) => $request->where('status', ReviewStatus::Pending)]))
            ->defaultSort('id', 'desc')
            ->columns([
                TextColumn::make('name')->label(__('panel.name'))->searchable(),
                TextColumn::make('phone')->label(__('panel.phone'))->searchable()->copyable(),
                TextColumn::make('parent_phone')->label(__('panel.parent_phone'))->searchable()->toggleable(),
                TextColumn::make('level.name')->label(__('panel.level')),
                TextColumn::make('subscriptions_count')->label(__('panel.subscriptions'))->badge(),
                IconColumn::make('has_pending_device')->label(__('panel.pending_device'))->boolean()->trueColor('warning'),
                IconColumn::make('blocked_at')->label(__('panel.blocked'))->boolean()->getStateUsing(fn (User $record) => $record->blocked_at !== null)->trueColor('danger'),
                TextColumn::make('created_at')->label(__('panel.created_at'))->date()->sortable()->toggleable(),
            ])
            ->filters([
                SelectFilter::make('level_id')->label(__('panel.level'))->relationship('level', 'name'),
                SelectFilter::make('category')->label(__('panel.subscribed_to'))
                    ->options(fn () => Category::query()->orderBy('level_id')->orderBy('position')->pluck('name', 'id'))
                    ->query(fn (Builder $query, array $data) => $query->when($data['value'], fn (Builder $query, $categoryId) => $query
                        ->whereHas('subscriptions', fn (Builder $subscription) => $subscription->active()->where('category_id', $categoryId)))),
                TernaryFilter::make('blocked_at')->label(__('panel.blocked'))->nullable(),
            ])
            ->recordActions([
                Action::make('activate')
                    ->label(__('panel.activate_category'))
                    ->icon('heroicon-o-lock-open')
                    ->color('success')
                    ->authorize('update')
                    ->schema([
                        Select::make('category_id')->label(__('panel.category'))->required()
                            ->options(fn (User $record) => Category::query()->where('level_id', $record->level_id)->orderBy('position')->pluck('name', 'id')),
                        DatePicker::make('ends_at')->label(__('panel.access_ends_at'))->helperText(__('panel.access_ends_at_help'))->afterOrEqual('today'),
                    ])
                    ->action(function (User $record, array $data, SubscriptionService $subscriptions) {
                        $subscriptions->grant(
                            $record,
                            Category::query()->where('level_id', $record->level_id)->findOrFail($data['category_id']),
                            $data['ends_at'] ? Carbon::parse($data['ends_at'])->endOfDay() : null,
                            auth()->user(),
                            null,
                        );
                        Notification::make()->title(__('panel.category_activated'))->success()->send();
                    }),
                Action::make('approveDevice')
                    ->label(__('panel.approve_device'))
                    ->icon('heroicon-o-device-phone-mobile')
                    ->color('warning')
                    ->requiresConfirmation()
                    ->modalDescription(__('panel.approve_device_help'))
                    ->authorize('update')
                    ->visible(fn (User $record) => (bool) $record->has_pending_device)
                    ->action(fn (User $record, DeviceService $devices) => $devices->approve(
                        $record->deviceResetRequests()->where('status', ReviewStatus::Pending)->latest('id')->firstOrFail(),
                        auth()->user(),
                    )),
                ActionGroup::make([
                    EditAction::make(),
                    Action::make('resetPassword')
                        ->label(__('panel.reset_password'))
                        ->icon('heroicon-o-key')
                        ->authorize('update')
                        ->schema([TextInput::make('password')->label(__('panel.new_password'))->password()->revealable()->required()->minLength(8)->maxLength(64)])
                        ->action(function (User $record, array $data, AuthService $auth) {
                            $auth->resetPassword($record, $data['password']);
                            Notification::make()->title(__('panel.password_reset_done'))->success()->send();
                        }),
                    Action::make('block')
                        ->label(fn (User $record) => $record->blocked_at ? __('panel.unblock') : __('panel.block'))
                        ->icon(fn (User $record) => $record->blocked_at ? 'heroicon-o-check-circle' : 'heroicon-o-no-symbol')
                        ->color(fn (User $record) => $record->blocked_at ? 'success' : 'danger')
                        ->requiresConfirmation()
                        ->authorize('update')
                        ->action(fn (User $record, AuthService $auth) => $auth->toggleBlock($record)),
                    DeleteAction::make(),
                ]),
            ])
            ->toolbarActions([
                BulkAction::make('export')
                    ->label(__('panel.export_xlsx'))
                    ->icon('heroicon-o-arrow-down-tray')
                    ->action(fn (Collection $records) => XlsxExport::download('students.xlsx',
                        [__('panel.name'), __('panel.phone'), __('panel.parent_phone'), __('panel.level'), __('panel.subscriptions'), __('panel.created_at')],
                        $records->loadMissing('level:id,name')
                            ->loadCount(['subscriptions' => fn (Builder $subscription) => $subscription->active()])
                            ->map(fn (User $student) => [
                                $student->name, $student->phone, $student->parent_phone, $student->level?->name,
                                $student->subscriptions_count, $student->created_at->toDateString(),
                            ]),
                    )),
            ]);
    }
}
