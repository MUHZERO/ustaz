<?php

namespace App\Services;

use App\Exceptions\CodeExpiredException;
use App\Exceptions\CodeInvalidException;
use App\Exceptions\CodeUsedUpException;
use App\Jobs\GenerateCodeBatch;
use App\Models\ActivationCode;
use App\Models\Category;
use App\Models\CodeRedemption;
use App\Models\Subscription;
use App\Models\User;
use Carbon\CarbonInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class ActivationCodeService
{
    public const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    public const LENGTH = 10;

    private const QUEUE_ABOVE = 200;

    public function __construct(private readonly SubscriptionService $subscriptions) {}

    public function generate(Category $category, int $count, int $maxUses, ?CarbonInterface $endsAt, ?CarbonInterface $expiresAt): string
    {
        $batchId = (string) Str::uuid();

        if ($count > self::QUEUE_ABOVE) {
            GenerateCodeBatch::dispatch($batchId, $category->id, $count, $maxUses, $endsAt, $expiresAt);
        } else {
            $this->fillBatch($batchId, $category->id, $count, $maxUses, $endsAt, $expiresAt);
        }

        return $batchId;
    }

    /**
     * Inserts until the batch holds $count codes; a colliding code is skipped by
     * the unique index and replaced on the next pass.
     */
    public function fillBatch(string $batchId, int $categoryId, int $count, int $maxUses, ?CarbonInterface $endsAt, ?CarbonInterface $expiresAt): void
    {
        $now = now();

        while (($missing = $count - ActivationCode::query()->where('batch_id', $batchId)->count()) > 0) {
            foreach (array_chunk(range(1, $missing), 500) as $chunk) {
                ActivationCode::query()->insertOrIgnore(array_map(fn () => [
                    'code' => $this->randomCode(),
                    'category_id' => $categoryId,
                    'batch_id' => $batchId,
                    'ends_at' => $endsAt,
                    'expires_at' => $expiresAt,
                    'max_uses' => $maxUses,
                    'uses_count' => 0,
                    'created_at' => $now,
                    'updated_at' => $now,
                ], $chunk));
            }
        }
    }

    public function normalize(string $raw): string
    {
        return strtoupper(preg_replace('/\s+/', '', $raw) ?? '');
    }

    public function redeem(User $user, string $raw): Subscription
    {
        return DB::transaction(function () use ($user, $raw) {
            $code = ActivationCode::query()->with('category:id,level_id')->where('code', $this->normalize($raw))->first();

            if ($code === null || $code->category->level_id !== $user->level_id) {
                throw new CodeInvalidException;
            }

            if ($code->expires_at !== null && $code->expires_at->isPast()) {
                throw new CodeExpiredException;
            }

            if (CodeRedemption::query()->where(['activation_code_id' => $code->id, 'user_id' => $user->id])->exists()) {
                throw new CodeInvalidException;
            }

            $this->consume($code);

            $redemption = CodeRedemption::query()->create([
                'activation_code_id' => $code->id,
                'user_id' => $user->id,
                'created_at' => now(),
            ]);

            return $this->subscriptions->grant($user, $code->category, $code->ends_at, null, $redemption);
        });
    }

    /**
     * One guarded UPDATE: of two concurrent redemptions of the last use, the
     * database lets exactly one increment through, on any driver.
     */
    public function consume(ActivationCode $code): void
    {
        $updated = ActivationCode::query()
            ->whereKey($code->id)
            ->whereColumn('uses_count', '<', 'max_uses')
            ->increment('uses_count');

        if ($updated === 0) {
            throw new CodeUsedUpException;
        }
    }

    private function randomCode(): string
    {
        $last = strlen(self::ALPHABET) - 1;

        return implode('', array_map(fn () => self::ALPHABET[random_int(0, $last)], range(1, self::LENGTH)));
    }
}
