<?php

namespace App\Http\Controllers\Panel;

use App\Http\Controllers\Controller;
use App\Models\ActivationCode;
use Illuminate\Contracts\View\View;

final class CodePrintController extends Controller
{
    public const PER_PAGE = 40;

    public function __invoke(string $batch): View
    {
        $codes = ActivationCode::query()
            ->with('category:id,name,level_id', 'category.level:id,name')
            ->where('batch_id', $batch)
            ->orderBy('id')
            ->get(['id', 'code', 'category_id', 'ends_at']);

        abort_if($codes->isEmpty(), 404);

        return view('codes.print', ['pages' => $codes->chunk(self::PER_PAGE), 'category' => $codes->first()->category]);
    }
}
