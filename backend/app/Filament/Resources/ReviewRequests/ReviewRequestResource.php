<?php

namespace App\Filament\Resources\ReviewRequests;

use App\Filament\Concerns\PendingBadge;
use App\Filament\Concerns\TranslatedLabels;
use App\Filament\Resources\ReviewRequests\Pages\ListReviewRequests;
use App\Filament\Resources\ReviewRequests\Tables\ReviewRequestsTable;
use App\Models\ReviewRequest;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class ReviewRequestResource extends Resource
{
    use PendingBadge, TranslatedLabels;

    protected static string $labelKey = 'review_request';

    protected static ?string $model = ReviewRequest::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedChatBubbleLeftRight;

    public static function table(Table $table): Table
    {
        return ReviewRequestsTable::configure($table);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListReviewRequests::route('/'),
        ];
    }
}
