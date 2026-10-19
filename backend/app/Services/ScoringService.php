<?php

namespace App\Services;

use App\Models\Attempt;
use App\Models\AttemptAnswer;

final class ScoringService
{
    /**
     * Marks each answer against its snapshot and stores the attempt totals.
     * Unanswered questions count as wrong.
     */
    public function score(Attempt $attempt): void
    {
        $answers = $attempt->answers()->get(['id', 'snapshot', 'chosen_option_id', 'is_correct']);
        $score = 0;
        $max = 0;

        foreach ($answers as $answer) {
            $mark = (int) ($answer->snapshot['mark'] ?? 1);
            $correct = $answer->chosen_option_id !== null && $answer->chosen_option_id === ($answer->snapshot['correct_option_id'] ?? null);
            $max += $mark;
            $score += $correct ? $mark : 0;

            if ($answer->is_correct !== $correct) {
                AttemptAnswer::query()->whereKey($answer->id)->update(['is_correct' => $correct]);
            }
        }

        $attempt->forceFill(['score' => $score, 'max_score' => $max])->save();
    }
}
