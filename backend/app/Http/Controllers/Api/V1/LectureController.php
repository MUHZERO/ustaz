<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\StudentContent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class LectureController extends Controller
{
    public function show(Request $request, int $lecture): JsonResponse
    {
        return response()->json(['data' => StudentContent::for($request->user())->lecture($lecture) ?? abort(404)]);
    }
}
