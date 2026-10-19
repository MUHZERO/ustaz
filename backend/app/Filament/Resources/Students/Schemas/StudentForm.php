<?php

namespace App\Filament\Resources\Students\Schemas;

use App\Models\User;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class StudentForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema->components([
            TextInput::make('name')->label(__('panel.name'))->required()->maxLength(120),
            TextInput::make('phone')->label(__('panel.phone'))->tel()->required()->regex(User::PHONE_PATTERN)->unique(ignoreRecord: true),
            TextInput::make('parent_phone')->label(__('panel.parent_phone'))->tel()->regex(User::PHONE_PATTERN),
            Select::make('level_id')->label(__('panel.level'))->relationship('level', 'name')->required(),
        ]);
    }
}
