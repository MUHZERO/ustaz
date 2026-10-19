<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('segments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lecture_id')->constrained()->cascadeOnDelete();
            $table->string('type');
            $table->unsignedInteger('position')->default(0);
            $table->string('title');
            $table->boolean('is_gating')->default(false);
            $table->string('youtube_id')->nullable();
            $table->unsignedInteger('duration_seconds')->nullable();
            $table->string('pdf_path')->nullable();
            $table->foreignId('assessment_id')->nullable()->constrained()->nullOnDelete();
            $table->tinyInteger('pass_percent')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('segments');
    }
};
