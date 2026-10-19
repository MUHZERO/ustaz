<?php

namespace App\Filament\Widgets;

use App\Enums\ReviewStatus;
use App\Filament\Resources\DeviceResetRequests\DeviceResetRequestResource;
use App\Filament\Resources\ReviewRequests\ReviewRequestResource;
use App\Models\DeviceResetRequest;
use App\Models\ReviewRequest;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class PendingRequests extends StatsOverviewWidget
{
    protected function getStats(): array
    {
        return [
            Stat::make(__('panel.pending_device_resets'), DeviceResetRequest::query()->where('status', ReviewStatus::Pending)->count())
                ->icon('heroicon-o-device-phone-mobile')
                ->url(DeviceResetRequestResource::getUrl()),
            Stat::make(__('panel.pending_reviews'), ReviewRequest::query()->where('status', ReviewStatus::Pending)->count())
                ->icon('heroicon-o-chat-bubble-left-right')
                ->url(ReviewRequestResource::getUrl()),
        ];
    }
}
