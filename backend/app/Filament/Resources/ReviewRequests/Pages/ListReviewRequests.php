<?php

namespace App\Filament\Resources\ReviewRequests\Pages;

use App\Filament\Resources\ReviewRequests\ReviewRequestResource;
use Filament\Resources\Pages\ListRecords;

class ListReviewRequests extends ListRecords
{
    protected static string $resource = ReviewRequestResource::class;
}
