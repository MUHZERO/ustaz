<?php

namespace App\Jobs;

use App\Services\Push\PushSender;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

final class SendPush implements ShouldQueue
{
    use Queueable;

    /**
     * @param  array<int, string>  $tokens
     * @param  array<string, string|int>  $data
     */
    public function __construct(
        public readonly array $tokens,
        public readonly string $title,
        public readonly string $body,
        public readonly array $data = [],
    ) {}

    public function handle(PushSender $push): void
    {
        $push->send($this->tokens, $this->title, $this->body, $this->data);
    }
}
