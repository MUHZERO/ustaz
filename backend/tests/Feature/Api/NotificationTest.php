<?php

use App\Enums\DeviceStatus;
use App\Models\Category;
use App\Models\Level;
use App\Models\Subscription;
use App\Models\User;
use App\Notifications\StudentNotification;
use App\Services\DeviceService;
use App\Services\Push\FcmPushSender;
use App\Services\Push\LogPushSender;
use App\Services\Push\NotificationAudience;
use App\Services\Push\PushSender;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;

uses(RefreshDatabase::class);

const NOTIFY_DEVICE = '88888888-8888-4888-8888-888888888888';

beforeEach(function () {
    $this->level = Level::factory()->create();
    $this->student = User::factory()->student()->create(['level_id' => $this->level->id]);
    app(DeviceService::class)->bind($this->student, NOTIFY_DEVICE);
    $this->api = fn () => $this->actingAs($this->student, 'sanctum')->withHeader('X-Device-Id', NOTIFY_DEVICE);
});

it('notification is stored and listed', function () {
    $this->student->notify(new StudentNotification('عنوان', 'نص', ['route' => 'home']));

    ($this->api)()->getJson('/api/v1/notifications')->assertOk()
        ->assertJsonPath('data.0.title', 'عنوان')
        ->assertJsonPath('data.0.body', 'نص')
        ->assertJsonPath('data.0.data.route', 'home')
        ->assertJsonPath('data.0.read_at', null)
        ->assertJsonPath('meta.per_page', 20);
});

it('mark as read', function () {
    $this->student->notify(new StudentNotification('عنوان', 'نص'));
    $id = $this->student->notifications()->first()->id;

    ($this->api)()->postJson("/api/v1/notifications/{$id}/read")->assertNoContent();

    expect($this->student->notifications()->first()->read_at)->not->toBeNull();
});

it('cannot read another student notification', function () {
    $other = User::factory()->student()->create();
    $other->notify(new StudentNotification('x', 'y'));

    ($this->api)()->postJson('/api/v1/notifications/'.$other->notifications()->first()->id.'/read')->assertNotFound();
});

it('log driver is used without firebase credentials', function () {
    config(['services.push.driver' => 'log']);

    expect(app(PushSender::class))->toBeInstanceOf(LogPushSender::class);
});

it('push goes to the active device token', function () {
    $pushed = [];
    app()->instance(PushSender::class, new class($pushed) implements PushSender
    {
        public function __construct(private array &$pushed) {}

        public function send(array $tokens, string $title, string $body, array $data = []): void
        {
            $this->pushed[] = compact('tokens', 'title');
        }
    });
    $this->student->devices()->where('status', DeviceStatus::Active)->update(['fcm_token' => 'token-a']);

    $this->student->notify(new StudentNotification('درس جديد', 'نص'));

    expect($pushed)->toBe([['tokens' => ['token-a'], 'title' => 'درس جديد']]);
});

it('fcm driver posts one message per token with an oauth token', function () {
    $key = openssl_pkey_new(['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA]);
    openssl_pkey_export($key, $pem);
    $credentials = ['project_id' => 'demo-project', 'client_email' => 'push@demo.iam.gserviceaccount.com', 'private_key' => $pem, 'token_uri' => 'https://oauth2.googleapis.com/token'];
    Http::fake([
        'oauth2.googleapis.com/*' => Http::response(['access_token' => 'ya29.test', 'expires_in' => 3600]),
        'fcm.googleapis.com/*' => Http::response(['name' => 'ok']),
    ]);

    (new FcmPushSender($credentials))->send(['t1', 't2'], 'عنوان', 'نص', ['route' => 'home']);

    Http::assertSentCount(3);
    Http::assertSent(fn ($request) => str_contains($request->url(), 'projects/demo-project/messages:send')
        && $request->hasHeader('Authorization', 'Bearer ya29.test')
        && $request['message']['token'] === 't1'
        && $request['message']['data']['route'] === 'home');
});

it('audience by category only includes subscribed students', function () {
    $category = Category::factory()->for($this->level)->create();
    Subscription::factory()->for($this->student)->for($category)->create();
    User::factory()->student()->create(['level_id' => $this->level->id]);
    $expired = User::factory()->student()->create(['level_id' => $this->level->id]);
    Subscription::factory()->for($expired)->for($category)->create(['ends_at' => now()->subDay()]);

    $ids = NotificationAudience::category($category->id)->pluck('id')->all();

    expect($ids)->toBe([$this->student->id]);
});

it('audience by level includes only students of that level', function () {
    User::factory()->student()->create();
    User::factory()->teacher()->create();

    expect(NotificationAudience::level($this->level->id)->pluck('id')->all())->toBe([$this->student->id]);
});
