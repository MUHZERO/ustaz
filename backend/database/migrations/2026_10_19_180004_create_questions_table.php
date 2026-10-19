<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('questions', function (Blueprint $table) {
            $table->id();
            $table->text('text')->nullable();
            $table->string('image_path')->nullable();
            $table->text('explanation')->nullable();
            $table->tinyInteger('difficulty')->nullable();
            $table->foreignId('level_id')->constrained()->cascadeOnDelete();
            $table->timestamp('archived_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('questions');
    }
};
