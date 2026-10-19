<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\LevelResource;
use App\Models\Level;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class LevelController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return LevelResource::collection(Level::orderBy('position')->get());
    }
}
