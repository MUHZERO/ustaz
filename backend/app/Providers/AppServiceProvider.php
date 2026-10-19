<?php

namespace App\Providers;

use App\Models\Announcement;
use App\Models\Assessment;
use App\Models\Category;
use App\Models\Lecture;
use App\Models\Paper;
use App\Models\Segment;
use App\Observers\ContentObserver;
use App\Services\Push\FcmPushSender;
use App\Services\Push\LogPushSender;
use App\Services\Push\PushSender;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(PushSender::class, fn () => config('services.push.driver') === 'fcm'
            ? new FcmPushSender(json_decode((string) file_get_contents((string) config('services.push.firebase_credentials')), true))
            : new LogPushSender);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Model::shouldBeStrict(! $this->app->isProduction());

        RateLimiter::for('login', fn (Request $request) => Limit::perMinute(5)
            ->by($request->input('phone').'|'.$request->ip()));

        RateLimiter::for('progress', fn (Request $request) => Limit::perMinute(10)
            ->by($request->user()?->id.'|'.$request->input('segment_id')));
        RateLimiter::for('answers', fn (Request $request) => Limit::perMinute(60)->by((string) $request->user()?->id));
        RateLimiter::for('redeem', fn (Request $request) => Limit::perMinute(10)->by((string) $request->user()?->id));

        Category::observe(ContentObserver::class);
        Lecture::observe(ContentObserver::class);
        Segment::observe(ContentObserver::class);
        Paper::observe(ContentObserver::class);
        Assessment::observe(ContentObserver::class);
        Announcement::observe(ContentObserver::class);
    }
}
