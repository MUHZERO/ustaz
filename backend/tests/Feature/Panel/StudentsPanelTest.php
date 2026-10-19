<?php

use App\Enums\AssessmentKind;
use App\Enums\DeviceStatus;
use App\Enums\ReviewStatus;
use App\Filament\Pages\ExamReport;
use App\Filament\Pages\LectureReport;
use App\Filament\Pages\SendNotification;
use App\Filament\Resources\ActivationCodes\Pages\ListActivationCodes;
use App\Filament\Resources\DeviceResetRequests\Pages\ListDeviceResetRequests;
use App\Filament\Resources\ReviewRequests\Pages\ListReviewRequests;
use App\Filament\Resources\Students\Pages\ListStudents;
use App\Models\ActivationCode;
use App\Models\Assessment;
use App\Models\Attempt;
use App\Models\Category;
use App\Models\DeviceResetRequest;
use App\Models\Lecture;
use App\Models\Level;
use App\Models\ReviewRequest;
use App\Models\Subscription;
use App\Models\User;
use App\Notifications\StudentNotification;
use App\Services\ActivationCodeService;
use App\Services\DeviceService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;

use function Pest\Livewire\livewire;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->level = Level::factory()->create();
    $this->category = Category::factory()->for($this->level)->create();
    $this->student = User::factory()->student()->create(['level_id' => $this->level->id]);
    $this->assistant = User::factory()->assistant()->create();
    $this->actingAs($this->assistant);
});

it('students list shows only students and searches by phone', function () {
    $other = User::factory()->student()->create(['level_id' => $this->level->id]);

    livewire(ListStudents::class)
        ->assertCanSeeTableRecords([$this->student, $other])
        ->assertCanNotSeeTableRecords([$this->assistant])
        ->searchTable($this->student->phone)
        ->assertCanSeeTableRecords([$this->student])
        ->assertCanNotSeeTableRecords([$other]);
});

it('assistant can activate a category for a student', function () {
    livewire(ListStudents::class)
        ->callTableAction('activate', $this->student, data: ['category_id' => $this->category->id, 'ends_at' => null])
        ->assertHasNoTableActionErrors();

    $subscription = Subscription::query()->firstOrFail();
    expect($subscription->category_id)->toBe($this->category->id)
        ->and($subscription->ends_at)->toBeNull()
        ->and($subscription->granted_by)->toBe($this->assistant->id);
});

it('reset password changes hash and revokes tokens', function () {
    $this->student->createToken('device');

    livewire(ListStudents::class)
        ->callTableAction('resetPassword', $this->student, data: ['password' => 'newpass123'])
        ->assertHasNoTableActionErrors();

    expect(Hash::check('newpass123', $this->student->fresh()->password))->toBeTrue()
        ->and($this->student->tokens()->count())->toBe(0);
});

it('block toggles the student', function () {
    livewire(ListStudents::class)->callTableAction('block', $this->student);

    expect($this->student->fresh()->blocked_at)->not->toBeNull();
});

it('approving a device reset activates the new device', function () {
    app(DeviceService::class)->bind($this->student, '11111111-1111-4111-8111-111111111111');
    app(DeviceService::class)->bind($this->student, '22222222-2222-4222-8222-222222222222');
    $request = DeviceResetRequest::query()->firstOrFail();

    livewire(ListDeviceResetRequests::class)->callTableAction('approve', $request)->assertHasNoTableActionErrors();

    expect($this->student->devices()->where('status', DeviceStatus::Active)->value('device_uuid'))->toBe('22222222-2222-4222-8222-222222222222');
});

it('generate batch action creates codes', function () {
    livewire(ListActivationCodes::class)
        ->callAction('generate', data: ['category_id' => $this->category->id, 'count' => 25, 'max_uses' => 1, 'ends_at' => null, 'expires_at' => null])
        ->assertHasNoActionErrors();

    expect(ActivationCode::count())->toBe(25);
});

it('print sheet renders codes rtl', function () {
    $batch = app(ActivationCodeService::class)->generate($this->category, 3, 1, null, null);

    $this->get(route('codes.print', $batch))->assertOk()
        ->assertSee('dir="rtl"', false)
        ->assertSee(ActivationCode::query()->first()->code);
});

it('students cannot open the print sheet', function () {
    $batch = app(ActivationCodeService::class)->generate($this->category, 1, 1, null, null);

    $this->actingAs($this->student)->get(route('codes.print', $batch))->assertForbidden();
});

it('deciding a review request notifies the student', function () {
    Notification::fake();
    $attempt = Attempt::factory()->for($this->student)->create();
    $review = ReviewRequest::query()->create(['attempt_id' => $attempt->id, 'note' => 'راجع', 'status' => ReviewStatus::Pending]);

    livewire(ListReviewRequests::class)
        ->callTableAction('decide', $review, data: ['status' => 'accepted', 'reply' => 'تم'])
        ->assertHasNoTableActionErrors();

    expect($review->fresh()->status)->toBe(ReviewStatus::Accepted);
    Notification::assertSentTo($this->student, StudentNotification::class);
});

it('assistant cannot delete students', function () {
    livewire(ListStudents::class)->assertTableActionHidden('delete', $this->student);
});

it('send notification to a category queues only subscribed students', function () {
    Notification::fake();
    $subscriber = User::factory()->student()->create(['level_id' => $this->level->id]);
    Subscription::factory()->for($subscriber)->for($this->category)->create();

    livewire(SendNotification::class)
        ->callAction('send', data: ['title' => 'تنبيه', 'body' => 'حصة إضافية', 'audience' => 'category', 'category_id' => $this->category->id])
        ->assertHasNoActionErrors();

    Notification::assertSentTo($subscriber, StudentNotification::class, fn ($notification) => $notification->title === 'تنبيه');
    Notification::assertNotSentTo($this->student, StudentNotification::class);
});

it('lecture report page lists the chosen lecture', function () {
    $lecture = Lecture::factory()->for($this->category)->create();
    Subscription::factory()->for($this->student)->for($this->category)->create();

    livewire(LectureReport::class)
        ->filterTable('lecture', $lecture->id)
        ->assertSee($this->student->phone);
});

it('exam report page lists absent students', function () {
    $exam = Assessment::factory()->create(['kind' => AssessmentKind::Exam, 'category_id' => $this->category->id]);
    Subscription::factory()->for($this->student)->for($this->category)->create();

    livewire(ExamReport::class)
        ->filterTable('exam', $exam->id)
        ->assertSee($this->student->phone)
        ->assertSee(__('panel.absent'));
});

it('exports selected students to xlsx', function () {
    livewire(ListStudents::class)
        ->callTableBulkAction('export', [$this->student])
        ->assertFileDownloaded('students.xlsx');
});

it('exports selected codes to xlsx', function () {
    app(ActivationCodeService::class)->generate($this->category, 2, 1, null, null);

    livewire(ListActivationCodes::class)
        ->callTableBulkAction('export', ActivationCode::all())
        ->assertFileDownloaded('codes.xlsx');
});
