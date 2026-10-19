<?php

namespace App\Services\Push;

interface PushSender
{
    /**
     * @param  array<int, string>  $tokens
     * @param  array<string, string|int>  $data
     */
    public function send(array $tokens, string $title, string $body, array $data = []): void;
}
