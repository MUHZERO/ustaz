<?php

namespace App\Services;

use App\Models\Category;
use App\Models\CodeRedemption;
use App\Models\Subscription;
use App\Models\User;
use Carbon\CarbonInterface;

final class SubscriptionService
{
    /**
     * One row per student and category. Granting again never shortens access:
     * a lifetime grant (null end) wins, otherwise the later end date is kept.
     * The Subscription model flushes the student's cache on save.
     */
    public function grant(User $user, Category $category, ?CarbonInterface $endsAt, ?User $by, ?CodeRedemption $redemption): Subscription
    {
        $subscription = Subscription::query()->firstOrNew(['user_id' => $user->id, 'category_id' => $category->id]);

        $subscription->starts_at ??= now();
        $subscription->ends_at = $this->laterEnd($subscription->exists ? $subscription->ends_at : $endsAt, $endsAt);
        $subscription->granted_by = $by?->id ?? $subscription->granted_by;
        $subscription->code_redemption_id = $redemption?->id ?? $subscription->code_redemption_id;
        $subscription->save();

        return $subscription;
    }

    private function laterEnd(?CarbonInterface $current, ?CarbonInterface $new): ?CarbonInterface
    {
        if ($current === null || $new === null) {
            return null;
        }

        return $new->greaterThan($current) ? $new : $current;
    }
}
