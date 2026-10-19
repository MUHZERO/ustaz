<?php

namespace App\Http\Requests\Api;

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
        $phone = ['regex:/^01[0125][0-9]{8}$/'];

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
