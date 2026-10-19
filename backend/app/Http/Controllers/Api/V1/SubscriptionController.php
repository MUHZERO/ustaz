<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\SubscriptionResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

final class SubscriptionController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        return SubscriptionResource::collection(
            $request->user()->subscriptions()
                ->active()
                ->with('category:id,name')
                ->orderBy('category_id')
                ->get(),
        );
    }
}
