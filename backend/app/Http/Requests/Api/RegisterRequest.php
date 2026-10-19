<?php

namespace App\Http\Requests\Api;

use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        $phone = ['regex:'.User::PHONE_PATTERN];

        return [
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', ...$phone, 'unique:users,phone'],
            'parent_phone' => ['nullable', ...$phone],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'level_id' => ['required', 'integer', 'exists:levels,id'],
            'device_id' => ['required', 'uuid'],
        ];
    }
}
