<?php

use App\Services\CacheService;
use Illuminate\Support\Facades\Cache;

it('returns the callback value and caches it', function () {
    $calls = 0;
    $service = app(CacheService::class);

    $first = $service->remember(['level:1'], 'home', 60, function () use (&$calls) {
        $calls++;

        return ['ok' => true];
    });
    $second = $service->remember(['level:1'], 'home', 60, function () use (&$calls) {
        $calls++;

        return ['ok' => false];
    });

    expect($first)->toBe(['ok' => true])
        ->and($second)->toBe(['ok' => true])
        ->and($calls)->toBe(1);
});

it('falls back to the callback when the cache store throws', function () {
    Cache::shouldReceive('supportsTags')->andThrow(new RuntimeException('redis down'));
    Cache::shouldReceive('tags')->andThrow(new RuntimeException('redis down'));
    Cache::shouldReceive('remember')->andThrow(new RuntimeException('redis down'));

    $value = app(CacheService::class)->remember(['level:1'], 'home', 60, fn () => 'fresh');

    expect($value)->toBe('fresh');
});

it('flush clears keys of the given tag only', function () {
    $service = app(CacheService::class);
    $service->remember(['level:1'], 'a', 60, fn () => 'one');
    $service->remember(['level:2'], 'b', 60, fn () => 'two');

    $service->flush(['level:1']);

    expect($service->remember(['level:1'], 'a', 60, fn () => 'one-new'))->toBe('one-new')
        ->and($service->remember(['level:2'], 'b', 60, fn () => 'two-new'))->toBe('two');
});

it('works on a store without tag support', function () {
    config(['cache.default' => 'file']);
    Cache::forgetDriver('file');
    Cache::store('file')->flush();
    $service = app(CacheService::class);

    expect($service->remember(['level:9'], 'x', 60, fn () => 'v'))->toBe('v');
    $service->flush(['level:9']);
    expect($service->remember(['level:9'], 'x', 60, fn () => 'v2'))->toBe('v2');
});
