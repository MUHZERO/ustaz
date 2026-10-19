<?php

namespace App\Filament\Resources\Lectures;

use App\Filament\Concerns\TranslatedLabels;
use App\Filament\Resources\Lectures\Pages\CreateLecture;
use App\Filament\Resources\Lectures\Pages\EditLecture;
use App\Filament\Resources\Lectures\Pages\ListLectures;
use App\Filament\Resources\Lectures\Schemas\LectureForm;
use App\Filament\Resources\Lectures\Tables\LecturesTable;
use App\Models\Lecture;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class LectureResource extends Resource
{
    use TranslatedLabels;

    protected static string $labelKey = 'lecture';

    protected static ?string $model = Lecture::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedRectangleStack;

    protected static ?string $recordTitleAttribute = 'title';

    public static function form(Schema $schema): Schema
    {
        return LectureForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return LecturesTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListLectures::route('/'),
            'create' => CreateLecture::route('/create'),
            'edit' => EditLecture::route('/{record}/edit'),
        ];
    }
}
