<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\StudentContent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class CategoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(['data' => StudentContent::for($request->user())->categories()]);
    }

    public function show(Request $request, int $category): JsonResponse
    {
        return response()->json(['data' => StudentContent::for($request->user())->category($category) ?? abort(404)]);
    }
}
