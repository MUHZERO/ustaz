<?php

namespace App\Services\Push;

use Illuminate\Support\Facades\Log;

/**
 * Default driver: the demo and local setups run without a Firebase project.
 * Tokens are never written to the log.
 */
final class LogPushSender implements PushSender
{
    public function send(array $tokens, string $title, string $body, array $data = []): void
    {
        Log::info('push skipped (log driver)', ['devices' => count($tokens), 'title' => $title]);
    }
}
