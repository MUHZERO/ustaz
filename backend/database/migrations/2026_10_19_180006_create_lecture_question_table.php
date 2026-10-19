<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lecture_question', function (Blueprint $table) {
            $table->foreignId('lecture_id')->constrained()->cascadeOnDelete();
            $table->foreignId('question_id')->constrained()->cascadeOnDelete();
            $table->primary(['lecture_id', 'question_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lecture_question');
    }
};
