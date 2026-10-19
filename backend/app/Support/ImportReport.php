<?php

namespace App\Support;

final class ImportReport
{
    /**
     * @param  array<int, string>  $errors  spreadsheet row number => reason
     */
    public function __construct(
        public readonly int $created,
        public readonly array $errors,
    ) {}
}
