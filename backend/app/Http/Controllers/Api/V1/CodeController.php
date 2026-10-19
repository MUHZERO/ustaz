<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\RedeemCodeRequest;
use App\Services\ActivationCodeService;
use App\Services\StudentContent;
use Illuminate\Http\JsonResponse;

final class CodeController extends Controller
{
    public function redeem(RedeemCodeRequest $request, ActivationCodeService $codes): JsonResponse
    {
        $subscription = $codes->redeem($request->user(), $request->validated('code'));
        $card = collect(StudentContent::for($request->user())->categories())->firstWhere('id', $subscription->category_id);

        return response()->json(['data' => ['category' => $card]]);
    }
}
