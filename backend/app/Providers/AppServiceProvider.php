<?php

namespace App\Providers;

use App\Models\Announcement;
use App\Models\Assessment;
use App\Models\Category;
use App\Models\Lecture;
use App\Models\Paper;
use App\Models\Segment;
use App\Observers\ContentObserver;
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
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Model::shouldBeStrict(! $this->app->isProduction());

        RateLimiter::for('login', fn (Request $request) => Limit::perMinute(5)
            ->by($request->input('phone').'|'.$request->ip()));

        Category::observe(ContentObserver::class);
        Lecture::observe(ContentObserver::class);
        Segment::observe(ContentObserver::class);
        Paper::observe(ContentObserver::class);
        Assessment::observe(ContentObserver::class);
        Announcement::observe(ContentObserver::class);
    }
}
