<?php

namespace App\Filament\Resources\DeviceResetRequests;

use App\Filament\Concerns\PendingBadge;
use App\Filament\Concerns\TranslatedLabels;
use App\Filament\Resources\DeviceResetRequests\Pages\ListDeviceResetRequests;
use App\Filament\Resources\DeviceResetRequests\Tables\DeviceResetRequestsTable;
use App\Models\DeviceResetRequest;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class DeviceResetRequestResource extends Resource
{
    use PendingBadge, TranslatedLabels;

    protected static string $labelKey = 'device_reset_request';

    protected static ?string $model = DeviceResetRequest::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedDevicePhoneMobile;

    public static function table(Table $table): Table
    {
        return DeviceResetRequestsTable::configure($table);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListDeviceResetRequests::route('/'),
        ];
    }
}
