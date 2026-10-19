<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\AnnouncementResource;
use App\Models\Announcement;
use Illuminate\Http\Request;

class AnnouncementController extends Controller
{
    public function __invoke(Request $request)
    {
        $user = $request->user();
        $levelId = $user->level_id;

        $query = Announcement::query()
            ->where(fn ($q) => $q->where('level_id', $levelId)->orWhereNull('level_id'))
            ->whereNotNull('published_at')
            ->where('published_at', '<=', now())
            ->orderByDesc('published_at');

        $paginator = $query->paginate(20);

        return response()->json([
            'data' => AnnouncementResource::collection($paginator->items()),
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
            ],
        ]);
    }
}
