<?php

use App\Enums\DeviceStatus;
use App\Models\DeviceResetRequest;
use App\Models\Level;
use App\Models\User;
use App\Services\DeviceService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

const DEVICE_A = '11111111-1111-4111-8111-111111111111';
const DEVICE_B = '22222222-2222-4222-8222-222222222222';

function registerPayload(array $overrides = []): array
{
    return array_merge([
        'name' => 'Sara Ali',
        'phone' => '01012345678',
        'parent_phone' => '01112345678',
        'password' => 'secret123',
        'password_confirmation' => 'secret123',
        'level_id' => Level::factory()->create()->id,
        'device_id' => DEVICE_A,
    ], $overrides);
}

function studentWithDevice(string $device = DEVICE_A): User
{
    $student = User::factory()->student()->create(['password' => 'secret123']);
    app(DeviceService::class)->bind($student, $device);

    return $student;
}

function loginAs(User $student, string $device)
{
    return test()->postJson('/api/v1/auth/login', [
        'phone' => $student->phone, 'password' => 'secret123', 'device_id' => $device,
    ]);
}

it('lists levels publicly', function () {
    Level::factory()->count(2)->create();

    $this->getJson('/api/v1/levels')->assertOk()->assertJsonCount(2, 'data')->assertJsonStructure(['data' => [['id', 'name']]]);
});

it('register creates student and binds device', function () {
    $response = $this->postJson('/api/v1/auth/register', registerPayload());

    $response->assertCreated()->assertJsonStructure(['data' => ['token', 'student' => ['id', 'name', 'phone', 'parent_phone', 'level' => ['id', 'name']]]]);
    $student = User::where('phone', '01012345678')->first();
    expect($student->devices()->where('device_uuid', DEVICE_A)->first()->status)->toBe(DeviceStatus::Active);
});

it('register rejects non egyptian phone', function () {
    $this->postJson('/api/v1/auth/register', registerPayload(['phone' => '0912345678']))
        ->assertStatus(422)->assertJsonPath('code', 'validation_failed')->assertJsonValidationErrors('phone');
});

it('login returns token on bound device', function () {
    $student = studentWithDevice();

    $token = loginAs($student, DEVICE_A)->assertOk()->json('data.token');

    $this->withToken($token)->withHeader('X-Device-Id', DEVICE_A)->getJson('/api/v1/me')
        ->assertOk()->assertJsonPath('data.phone', $student->phone);
});

it('second device is pending and first token survives', function () {
    $student = studentWithDevice();
    $first = loginAs($student, DEVICE_A)->json('data.token');

    loginAs($student, DEVICE_B)->assertForbidden()->assertJsonPath('code', 'device_pending');

    expect(DeviceResetRequest::where('user_id', $student->id)->count())->toBe(1);
    $this->withToken($first)->withHeader('X-Device-Id', DEVICE_A)->getJson('/api/v1/me')->assertOk();
});

it('approved reset moves access to new device', function () {
    $student = studentWithDevice();
    $old = loginAs($student, DEVICE_A)->json('data.token');
    loginAs($student, DEVICE_B);
    $teacher = User::factory()->teacher()->create();

    app(DeviceService::class)->approve(DeviceResetRequest::where('user_id', $student->id)->firstOrFail(), $teacher);

    $new = loginAs($student, DEVICE_B)->assertOk()->json('data.token');
    $this->withToken($new)->withHeader('X-Device-Id', DEVICE_B)->getJson('/api/v1/me')->assertOk();
    app('auth')->forgetGuards();
    $this->withToken($old)->withHeader('X-Device-Id', DEVICE_A)->getJson('/api/v1/me')->assertUnauthorized();
});

it('blocked student cannot login', function () {
    $student = studentWithDevice();
    $student->forceFill(['blocked_at' => now()])->save();

    loginAs($student, DEVICE_A)->assertForbidden()->assertJsonPath('code', 'account_blocked');
});

it('login is throttled', function () {
    $student = studentWithDevice();

    foreach (range(1, 5) as $i) {
        $this->postJson('/api/v1/auth/login', ['phone' => $student->phone, 'password' => 'wrong-pass', 'device_id' => DEVICE_A]);
    }

    $this->postJson('/api/v1/auth/login', ['phone' => $student->phone, 'password' => 'wrong-pass', 'device_id' => DEVICE_A])
        ->assertStatus(429)->assertJsonPath('code', 'too_many_requests');
});

it('wrong device id is rejected on protected routes', function () {
    $student = studentWithDevice();
    $token = loginAs($student, DEVICE_A)->json('data.token');

    $this->withToken($token)->withHeader('X-Device-Id', DEVICE_B)->getJson('/api/v1/me')
        ->assertForbidden()->assertJsonPath('code', 'device_pending');
});

it('updates profile and stores fcm token', function () {
    $student = studentWithDevice();
    $token = loginAs($student, DEVICE_A)->json('data.token');

    $this->withToken($token)->withHeader('X-Device-Id', DEVICE_A)->putJson('/api/v1/me', ['name' => 'New Name'])
        ->assertOk()->assertJsonPath('data.name', 'New Name');
    $this->withToken($token)->withHeader('X-Device-Id', DEVICE_A)->postJson('/api/v1/me/fcm-token', ['token' => 'fcm-123'])
        ->assertNoContent();
});

it('logout revokes the token', function () {
    $student = studentWithDevice();
    $token = loginAs($student, DEVICE_A)->json('data.token');

    $this->withToken($token)->withHeader('X-Device-Id', DEVICE_A)->postJson('/api/v1/auth/logout')->assertNoContent();
    app('auth')->forgetGuards();
    $this->withToken($token)->withHeader('X-Device-Id', DEVICE_A)->getJson('/api/v1/me')->assertUnauthorized()->assertJsonPath('code', 'unauthenticated');
});
