<?php

use App\Enums\UserRole;
use App\Models\Category;
use App\Models\User;
use Database\Seeders\DemoSeeder;
use Filament\Auth\Pages\Login;
use Illuminate\Foundation\Testing\RefreshDatabase;

use function Pest\Livewire\livewire;

uses(RefreshDatabase::class);

beforeEach(fn () => $this->seed(DemoSeeder::class));

it('serves 200 home and category requests from different students in under five seconds', function () {
    $students = User::query()->where('role', UserRole::Student)->with('activeDevice')->get();
    $categoryIds = Category::query()->whereIn('level_id', $students->pluck('level_id'))->pluck('id');
    $started = microtime(true);

    foreach (range(0, 199) as $i) {
        $student = $students[$i % $students->count()];
        $uri = $i % 2 === 0 ? '/api/v1/home' : '/api/v1/categories/'.$categoryIds[$i % $categoryIds->count()];

        $this->actingAs($student, 'sanctum')
            ->withHeader('X-Device-Id', $student->activeDevice->device_uuid)
            ->getJson($uri)
            ->assertOk();
    }

    expect(microtime(true) - $started)->toBeLessThan(5.0);
});

it('lets the demo teacher sign in to the panel', function () {
    livewire(Login::class)
        ->fillForm(['email' => 'teacher@ustaz.test', 'password' => 'password'])
        ->call('authenticate')
        ->assertHasNoFormErrors();

    expect(auth()->user()->role)->toBe(UserRole::Teacher);
    $this->get('/admin')->assertOk();
});
