<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\ContentService;
use App\Services\StudentContent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class HomeController extends Controller
{
    public function __invoke(Request $request, ContentService $content): JsonResponse
    {
        $student = $request->user();

        return response()->json([
            'data' => StudentContent::for($student)->home($content->announcements((int) $student->level_id)),
        ]);
    }
}
