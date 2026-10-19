<!doctype html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <title>{{ __('panel.codes_sheet') }} — {{ $category->level->name }} / {{ $category->name }}</title>
    <style>
        @page { size: A4; margin: 10mm; }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: Tahoma, Arial, sans-serif; color: #111; }
        .page { display: grid; grid-template-columns: repeat(4, 1fr); gap: 3mm; page-break-after: always; }
        .page:last-child { page-break-after: auto; }
        .card { border: 1px dashed #888; border-radius: 2mm; padding: 3mm 2mm; text-align: center; height: 25mm; display: flex; flex-direction: column; justify-content: center; gap: 1mm; }
        .meta { font-size: 9pt; color: #444; }
        .code { font: 700 13pt/1 'Courier New', monospace; letter-spacing: 1px; direction: ltr; }
        .toolbar { padding: 8px; text-align: center; }
        @media print { .toolbar { display: none; } }
    </style>
</head>
<body>
<div class="toolbar"><button onclick="window.print()">{{ __('panel.print') }}</button></div>
@foreach ($pages as $page)
    <section class="page">
        @foreach ($page as $code)
            <div class="card">
                <div class="meta">{{ $category->level->name }} — {{ $category->name }}</div>
                <div class="code">{{ $code->code }}</div>
                <div class="meta">{{ $code->ends_at ? __('panel.valid_until', ['date' => $code->ends_at->toDateString()]) : __('panel.lifetime') }}</div>
            </div>
        @endforeach
    </section>
@endforeach
</body>
</html>
