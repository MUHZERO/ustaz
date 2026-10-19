<?php

namespace App\Services\Push;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;

/**
 * Who receives a teacher's broadcast. Returns queries so callers can chunk.
 */
final class NotificationAudience
{
    /** @return Builder<User> */
    public static function all(): Builder
    {
        return User::query()->where('role', UserRole::Student)->whereNull('blocked_at')->orderBy('id');
    }

    /** @return Builder<User> */
    public static function level(int $levelId): Builder
    {
        return self::all()->where('level_id', $levelId);
    }

    /** @return Builder<User> */
    public static function category(int $categoryId): Builder
    {
        return self::all()->whereHas('subscriptions', fn (Builder $query) => $query->active()->where('category_id', $categoryId));
    }
}
