<?php

use App\Enums\SegmentType;
use App\Models\Category;
use App\Models\Lecture;
use App\Models\Level;
use App\Models\Segment;
use App\Models\Subscription;
use App\Models\User;
use App\Models\WatchProgress;
use App\Services\DeviceService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

const PROGRESS_DEVICE = '44444444-4444-4444-8444-444444444444';

beforeEach(function () {
    $level = Level::factory()->create();
    $this->student = User::factory()->student()->create(['level_id' => $level->id]);
    app(DeviceService::class)->bind($this->student, PROGRESS_DEVICE);
    $this->category = Category::factory()->for($level)->create(['is_free' => false]);
    $this->lecture = Lecture::factory()->for($this->category)->create(['published_at' => now()]);
    $this->segment = Segment::factory()->for($this->lecture)->create(['type' => SegmentType::Video, 'position' => 1, 'youtube_id' => 'v', 'duration_seconds' => 1000]);
    Subscription::factory()->for($this->student)->for($this->category)->create();

    $this->send = fn (array $body) => $this->actingAs($this->student, 'sanctum')
        ->withHeader('X-Device-Id', PROGRESS_DEVICE)
        ->postJson("/api/v1/lectures/{$this->lecture->id}/progress", $body + ['segment_id' => $this->segment->id]);
});

it('progress upserts one row', function () {
    ($this->send)(['position_seconds' => 100, 'watched_seconds' => 100])->assertNoContent();
    ($this->send)(['position_seconds' => 200, 'watched_seconds' => 200])->assertNoContent();

    expect(WatchProgress::count())->toBe(1)
        ->and(WatchProgress::first()->last_position_seconds)->toBe(200);
});

it('watched seconds never decrease', function () {
    ($this->send)(['position_seconds' => 500, 'watched_seconds' => 500]);
    ($this->send)(['position_seconds' => 10, 'watched_seconds' => 10]);

    expect(WatchProgress::first()->watched_seconds)->toBe(500)
        ->and(WatchProgress::first()->last_position_seconds)->toBe(10);
});

it('ninety percent marks completed', function () {
    ($this->send)(['position_seconds' => 899, 'watched_seconds' => 899]);
    expect(WatchProgress::first()->completed_at)->toBeNull();

    ($this->send)(['position_seconds' => 900, 'watched_seconds' => 900]);
    expect(WatchProgress::first()->completed_at)->not->toBeNull();
});

it('completion shows in the lecture progress', function () {
    ($this->send)(['position_seconds' => 950, 'watched_seconds' => 950]);

    $this->actingAs($this->student, 'sanctum')->withHeader('X-Device-Id', PROGRESS_DEVICE)
        ->getJson("/api/v1/categories/{$this->category->id}")
        ->assertJsonPath('data.lectures.0.progress_percent', 95);
});

it('locked segment progress is forbidden', function () {
    Subscription::query()->delete();

    ($this->send)(['position_seconds' => 10, 'watched_seconds' => 10])->assertForbidden()->assertJsonPath('code', 'locked');
});

it('segment must belong to the lecture', function () {
    $other = Segment::factory()->create(['type' => SegmentType::Video, 'youtube_id' => 'z', 'duration_seconds' => 10]);

    $this->actingAs($this->student, 'sanctum')->withHeader('X-Device-Id', PROGRESS_DEVICE)
        ->postJson("/api/v1/lectures/{$this->lecture->id}/progress", ['segment_id' => $other->id, 'position_seconds' => 1, 'watched_seconds' => 1])
        ->assertStatus(422)->assertJsonValidationErrors('segment_id');
});

it('rejects negative or absurd values', function () {
    ($this->send)(['position_seconds' => -1, 'watched_seconds' => 5])->assertStatus(422);
    ($this->send)(['position_seconds' => 5, 'watched_seconds' => 999999])->assertStatus(422);
});

it('progress endpoint is throttled at 10 per minute per segment', function () {
    foreach (range(1, 10) as $i) {
        ($this->send)(['position_seconds' => $i, 'watched_seconds' => $i])->assertNoContent();
    }

    ($this->send)(['position_seconds' => 11, 'watched_seconds' => 11])->assertStatus(429);
});
