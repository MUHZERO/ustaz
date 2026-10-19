<?php

namespace App\Filament\Concerns;

use App\Enums\ReviewStatus;

/**
 * Navigation badge with the number of requests still waiting for staff.
 */
trait PendingBadge
{
    public static function getNavigationBadge(): ?string
    {
        $pending = static::getModel()::query()->where('status', ReviewStatus::Pending)->count();

        return $pending > 0 ? (string) $pending : null;
    }

    public static function getNavigationBadgeColor(): string
    {
        return 'warning';
    }
}
