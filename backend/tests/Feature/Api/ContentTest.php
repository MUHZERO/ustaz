<?php

use App\Enums\AssessmentKind;
use App\Enums\SegmentType;
use App\Models\Announcement;
use App\Models\Assessment;
use App\Models\Category;
use App\Models\Lecture;
use App\Models\Level;
use App\Models\Paper;
use App\Models\Segment;
use App\Models\Subscription;
use App\Models\User;
use App\Services\DeviceService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

uses(RefreshDatabase::class);

const CONTENT_DEVICE = '33333333-3333-4333-8333-333333333333';

beforeEach(function () {
    $this->level = Level::factory()->create();
    $this->student = User::factory()->student()->create(['level_id' => $this->level->id]);
    app(DeviceService::class)->bind($this->student, CONTENT_DEVICE);

    $this->paid = Category::factory()->for($this->level)->create(['name' => 'أكتوبر', 'position' => 1, 'is_free' => false]);
    $this->free = Category::factory()->for($this->level)->create(['name' => 'مراجعة', 'position' => 2, 'is_free' => true]);

    $this->lecture = Lecture::factory()->for($this->paid)->create(['title' => 'الدرس الأول', 'position' => 1, 'is_free' => false, 'published_at' => now()]);
    $this->video = Segment::factory()->for($this->lecture)->create(['type' => SegmentType::Video, 'position' => 1, 'youtube_id' => 'SECRETID123', 'duration_seconds' => 600]);
    Segment::factory()->for($this->lecture)->create(['type' => SegmentType::Pdf, 'position' => 2, 'pdf_path' => 'papers/l1.pdf']);
    Paper::factory()->for($this->paid)->create(['title' => 'ملزمة', 'path' => 'papers/p1.pdf']);
    Assessment::factory()->create(['kind' => AssessmentKind::Exam, 'category_id' => $this->paid->id, 'opens_at' => now()->subHour(), 'closes_at' => now()->addHour(), 'duration_minutes' => 30]);
    Lecture::factory()->for($this->free)->create(['title' => 'مجاني', 'position' => 1, 'is_free' => false, 'published_at' => now()]);
    Announcement::factory()->create(['level_id' => $this->level->id, 'title' => 'إعلان', 'published_at' => now()]);

    $this->api = fn () => $this->actingAs($this->student, 'sanctum')->withHeader('X-Device-Id', CONTENT_DEVICE);
});

it('home returns announcements categories continue watching and free lectures', function () {
    ($this->api)()->getJson('/api/v1/home')->assertOk()
        ->assertJsonStructure(['data' => [
            'announcements' => [['id', 'title', 'body', 'image_url', 'created_at']],
            'continue_watching',
            'categories' => [['id', 'name', 'position', 'is_free', 'is_subscribed', 'ends_at', 'lectures_count', 'exams_count', 'papers_count']],
            'free' => [['id', 'title', 'position', 'is_free', 'is_locked', 'progress_percent', 'thumbnail_url']],
        ]])
        ->assertJsonPath('data.categories.0.name', 'أكتوبر')
        ->assertJsonPath('data.categories.0.is_subscribed', false)
        ->assertJsonPath('data.free.0.title', 'مجاني');
});

it('categories are ordered and flag subscriptions', function () {
    Subscription::factory()->for($this->student)->for($this->paid)->create(['ends_at' => null]);

    ($this->api)()->getJson('/api/v1/categories')->assertOk()
        ->assertJsonPath('data.0.id', $this->paid->id)
        ->assertJsonPath('data.0.is_subscribed', true)
        ->assertJsonPath('data.0.lectures_count', 1)
        ->assertJsonPath('data.0.exams_count', 1)
        ->assertJsonPath('data.0.papers_count', 1)
        ->assertJsonPath('data.1.is_free', true);
});

it('category detail lists lectures exams and papers', function () {
    Subscription::factory()->for($this->student)->for($this->paid)->create();

    ($this->api)()->getJson("/api/v1/categories/{$this->paid->id}")->assertOk()
        ->assertJsonStructure(['data' => [
            'category' => ['id', 'name'],
            'lectures' => [['id', 'title', 'is_locked']],
            'exams' => [['id', 'title', 'opens_at', 'closes_at', 'duration_minutes', 'state', 'attempt', 'is_locked']],
            'papers' => [['id', 'title', 'url']],
        ]])
        ->assertJsonPath('data.exams.0.state', 'open')
        ->assertJsonPath('data.lectures.0.is_locked', false);
});

it('papers empty when category locked', function () {
    ($this->api)()->getJson("/api/v1/categories/{$this->paid->id}")->assertOk()
        ->assertJsonCount(0, 'data.papers')
        ->assertJsonPath('data.lectures.0.is_locked', true);
});

it('locked lecture hides youtube id', function () {
    $response = ($this->api)()->getJson("/api/v1/lectures/{$this->lecture->id}")->assertOk();

    $response->assertJsonPath('data.is_locked', true)->assertJsonMissingPath('data.segments.0.video');
    expect($response->getContent())->not->toContain('SECRETID123');
});

it('unlocked lecture returns video and signed pdf', function () {
    Subscription::factory()->for($this->student)->for($this->paid)->create();

    ($this->api)()->getJson("/api/v1/lectures/{$this->lecture->id}")->assertOk()
        ->assertJsonPath('data.segments.0.type', 'video')
        ->assertJsonPath('data.segments.0.video.youtube_id', 'SECRETID123')
        ->assertJsonPath('data.segments.0.video.last_position_seconds', 0)
        ->assertJsonPath('data.segments.1.type', 'pdf')
        ->assertJson(fn ($json) => $json->where('data.segments.1.pdf.url', fn ($url) => str_contains($url, 'signature='))->etc());
});

it('other level lecture is not found', function () {
    $other = Lecture::factory()->create();

    ($this->api)()->getJson("/api/v1/lectures/{$other->id}")->assertNotFound()->assertJsonPath('code', 'not_found');
});

it('signed file url serves the file and rejects tampering', function () {
    Subscription::factory()->for($this->student)->for($this->paid)->create();
    Storage::fake('local');
    Storage::disk('local')->put('papers/l1.pdf', '%PDF-1.4 test');

    $url = ($this->api)()->getJson("/api/v1/lectures/{$this->lecture->id}")->json('data.segments.1.pdf.url');

    $this->get($url)->assertOk();
    $this->get($url.'x')->assertForbidden();
});

it('home uses at most 10 queries', function () {
    DB::enableQueryLog();
    ($this->api)()->getJson('/api/v1/home')->assertOk();

    expect(count(DB::getQueryLog()))->toBeLessThanOrEqual(10);
});

it('home query count does not grow with content', function () {
    DB::enableQueryLog();
    ($this->api)()->getJson('/api/v1/home')->assertOk();
    $small = count(DB::getQueryLog());

    Lecture::factory()->count(20)->for($this->paid)->create(['published_at' => now()])
        ->each(fn (Lecture $lecture) => Segment::factory()->for($lecture)->create(['type' => SegmentType::Video, 'youtube_id' => 'x', 'duration_seconds' => 60]));
    Cache::flush();
    DB::flushQueryLog();
    ($this->api)()->getJson('/api/v1/home')->assertOk();

    expect(count(DB::getQueryLog()))->toBe($small);
});

it('second home request uses 3 or fewer queries', function () {
    ($this->api)()->getJson('/api/v1/home')->assertOk();
    DB::flushQueryLog();
    DB::enableQueryLog();

    ($this->api)()->getJson('/api/v1/home')->assertOk();

    expect(count(DB::getQueryLog()))->toBeLessThanOrEqual(3);
});

it('teacher edit flushes level cache', function () {
    Subscription::factory()->for($this->student)->for($this->paid)->create();
    ($this->api)()->getJson("/api/v1/categories/{$this->paid->id}")->assertJsonPath('data.lectures.0.title', 'الدرس الأول');

    $this->lecture->update(['title' => 'عنوان جديد']);

    ($this->api)()->getJson("/api/v1/categories/{$this->paid->id}")->assertJsonPath('data.lectures.0.title', 'عنوان جديد');
});

it('lists announcements paginated', function () {
    ($this->api)()->getJson('/api/v1/announcements')->assertOk()
        ->assertJsonStructure(['data' => [['id', 'title']], 'meta' => ['current_page', 'last_page', 'per_page', 'total']])
        ->assertJsonPath('meta.per_page', 20);
});

it('video behind an unpassed gating quiz hides its youtube id', function () {
    Subscription::factory()->for($this->student)->for($this->paid)->create();
    $quiz = Assessment::factory()->create(['kind' => AssessmentKind::Quiz, 'lecture_id' => $this->lecture->id]);
    $this->video->update(['position' => 2]);
    Segment::factory()->for($this->lecture)->create(['type' => SegmentType::Quiz, 'position' => 1, 'assessment_id' => $quiz->id, 'is_gating' => true, 'pass_percent' => 50]);

    $response = ($this->api)()->getJson("/api/v1/lectures/{$this->lecture->id}")->assertOk()
        ->assertJsonPath('data.segments.0.type', 'quiz')
        ->assertJsonPath('data.segments.0.is_locked', false)
        ->assertJsonPath('data.segments.0.passed', false)
        ->assertJsonPath('data.segments.1.is_locked', true);

    expect($response->getContent())->not->toContain('SECRETID123');
});
