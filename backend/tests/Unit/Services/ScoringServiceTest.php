<?php

use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Services\ScoringService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

function answer(Attempt $attempt, ?int $chosen, int $correct, int $mark): void
{
    AttemptAnswer::factory()->for($attempt)->create([
        'snapshot' => ['text' => 'q', 'image_url' => null, 'options' => [], 'correct_option_id' => $correct, 'mark' => $mark],
        'chosen_option_id' => $chosen,
    ]);
}

it('score sums marks of correct answers', function () {
    $attempt = Attempt::factory()->create();
    answer($attempt, null, 1, 0);
    $attempt->answers()->delete();
    answer($attempt, 11, 11, 2);
    answer($attempt, 12, 13, 3);
    answer($attempt, 14, 14, 1);

    app(ScoringService::class)->score($attempt);

    expect((float) $attempt->fresh()->score)->toBe(3.0)
        ->and((float) $attempt->fresh()->max_score)->toBe(6.0)
        ->and($attempt->answers()->where('is_correct', true)->count())->toBe(2);
});

it('unanswered counts as wrong', function () {
    $attempt = Attempt::factory()->create();
    answer($attempt, null, 21, 2);

    app(ScoringService::class)->score($attempt);

    expect((float) $attempt->fresh()->score)->toBe(0.0)
        ->and($attempt->answers()->first()->is_correct)->toBeFalse();
});
