<?php

namespace App\Filament\Resources\ActivationCodes\Tables;

use App\Models\ActivationCode;
use App\Support\XlsxExport;
use Filament\Actions\Action;
use Filament\Actions\BulkAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Collection;

class ActivationCodesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('id', 'desc')
            ->columns([
                TextColumn::make('code')->label(__('panel.code'))->searchable()->copyable()->fontFamily('mono'),
                TextColumn::make('category.name')->label(__('panel.category')),
                TextColumn::make('uses_count')->label(__('panel.usage'))
                    ->formatStateUsing(fn (ActivationCode $record) => "{$record->uses_count} / {$record->max_uses}")
                    ->badge()
                    ->color(fn (ActivationCode $record) => $record->uses_count >= $record->max_uses ? 'gray' : 'success'),
                TextColumn::make('ends_at')->label(__('panel.access_ends_at'))->date()->placeholder(__('panel.lifetime')),
                TextColumn::make('expires_at')->label(__('panel.code_expires_at'))->date()->placeholder('—'),
                TextColumn::make('created_at')->label(__('panel.created_at'))->dateTime()->sortable(),
            ])
            ->filters([
                SelectFilter::make('category_id')->label(__('panel.category'))->relationship('category', 'name'),
                SelectFilter::make('batch_id')->label(__('panel.batch'))
                    ->options(fn () => ActivationCode::query()
                        ->selectRaw('batch_id, min(created_at) as created')
                        ->groupBy('batch_id')->orderByDesc('created')->limit(50)
                        ->pluck('created', 'batch_id')),
            ])
            ->recordActions([
                Action::make('print')
                    ->label(__('panel.print_batch'))
                    ->icon('heroicon-o-printer')
                    ->url(fn (ActivationCode $record) => route('codes.print', $record->batch_id), shouldOpenInNewTab: true),
            ])
            ->toolbarActions([
                BulkAction::make('export')
                    ->label(__('panel.export_xlsx'))
                    ->icon('heroicon-o-arrow-down-tray')
                    ->action(fn (Collection $records) => XlsxExport::download('codes.xlsx',
                        [__('panel.code'), __('panel.category'), __('panel.usage'), __('panel.access_ends_at'), __('panel.code_expires_at')],
                        $records->loadMissing('category:id,name')->map(fn (ActivationCode $code) => [
                            $code->code, $code->category->name, "{$code->uses_count}/{$code->max_uses}",
                            $code->ends_at?->toDateString() ?? __('panel.lifetime'), $code->expires_at?->toDateString() ?? '',
                        ]),
                    )),
                DeleteBulkAction::make(),
            ]);
    }
}
