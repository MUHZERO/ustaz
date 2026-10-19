<?php

namespace App\Filament\Resources\ActivationCodes;

use App\Filament\Concerns\TranslatedLabels;
use App\Filament\Resources\ActivationCodes\Pages\ListActivationCodes;
use App\Filament\Resources\ActivationCodes\Tables\ActivationCodesTable;
use App\Models\ActivationCode;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class ActivationCodeResource extends Resource
{
    use TranslatedLabels;

    protected static string $labelKey = 'activation_code';

    protected static ?string $model = ActivationCode::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedTicket;

    protected static ?string $recordTitleAttribute = 'code';

    public static function table(Table $table): Table
    {
        return ActivationCodesTable::configure($table);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListActivationCodes::route('/'),
        ];
    }
}
