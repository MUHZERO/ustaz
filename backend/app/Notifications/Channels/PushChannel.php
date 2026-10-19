<?php

namespace App\Notifications\Channels;

use App\Enums\DeviceStatus;
use App\Jobs\SendPush;
use App\Models\User;
use App\Notifications\StudentNotification;

final class PushChannel
{
    public function send(User $notifiable, StudentNotification $notification): void
    {
        $tokens = $notifiable->devices()
            ->where('status', DeviceStatus::Active)
            ->whereNotNull('fcm_token')
            ->pluck('fcm_token')
            ->all();

        if ($tokens !== []) {
            SendPush::dispatch($tokens, $notification->title, $notification->body, $notification->data);
        }
    }
}
