<?php

namespace App\Filament\Concerns;

/**
 * Resource names come from lang/{ar,en}/panel.php → models.{key}.
 * Each resource sets `protected static string $labelKey`.
 */
trait TranslatedLabels
{
    public static function getModelLabel(): string
    {
        return __('panel.models.'.static::$labelKey.'.one');
    }

    public static function getPluralModelLabel(): string
    {
        return __('panel.models.'.static::$labelKey.'.many');
    }
}
