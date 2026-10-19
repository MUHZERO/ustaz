<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\DeviceStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\FcmTokenRequest;
use App\Http\Requests\Api\UpdateProfileRequest;
use App\Http\Resources\StudentResource;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ProfileController extends Controller
{
    public function show(Request $request): StudentResource
    {
        return new StudentResource($request->user()->load('level'));
    }

    public function update(UpdateProfileRequest $request): StudentResource
    {
        $user = $request->user();
        $user->update($request->validated());

        return new StudentResource($user->load('level'));
    }

    public function fcmToken(FcmTokenRequest $request): Response
    {
        $request->user()->devices()
            ->where('status', DeviceStatus::Active)
            ->update(['fcm_token' => $request->validated()['token']]);

        return response()->noContent();
    }
}
