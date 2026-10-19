<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StudentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'phone' => $this->phone,
            'parent_phone' => $this->parent_phone,
            'level' => LevelResource::make($this->whenLoaded('level')),
            'created_at' => $this->created_at,
        ];
    }
}
