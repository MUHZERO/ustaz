<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('code_redemptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('activation_code_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamp('created_at')->nullable();

            $table->unique(['activation_code_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('code_redemptions');
    }
};
