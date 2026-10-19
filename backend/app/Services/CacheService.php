<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;

final class CacheService
{
    public function remember(array $tags, string $key, int $ttl, \Closure $callback): mixed
    {
        try {
            if (Cache::supportsTags()) {
                return Cache::tags($tags)->remember($key, $ttl, $callback);
            }

            return Cache::remember($key.':'.$this->versions($tags), $ttl, $callback);
        } catch (\Throwable $e) {
            report($e);

            return $callback();
        }
    }

    public function flush(array $tags): void
    {
        try {
            if (Cache::supportsTags()) {
                Cache::tags($tags)->flush();

                return;
            }

            foreach ($tags as $tag) {
                $versionKey = 'cache-tag-version:'.$tag;

                if (Cache::get($versionKey) === null) {
                    Cache::forever($versionKey, 1);
                } else {
                    Cache::increment($versionKey);
                }
            }
        } catch (\Throwable $e) {
            report($e);
        }
    }

    private function versions(array $tags): string
    {
        $parts = [];

        foreach ($tags as $tag) {
            $versionKey = 'cache-tag-version:'.$tag;
            $version = Cache::get($versionKey);

            if ($version === null) {
                Cache::forever($versionKey, 1);
                $version = 1;
            }

            $parts[] = $tag.'='.$version;
        }

        return implode(',', $parts);
    }
}
