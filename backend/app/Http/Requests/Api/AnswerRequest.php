<?php

namespace App\Http\Requests\Api;

use App\Models\Attempt;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class AnswerRequest extends FormRequest
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
        return [
            'question_id' => ['required', 'integer'],
            'option_id' => ['required', 'integer'],
        ];
    }

    /**
     * The question must be part of this attempt and the option must be one of
     * that question's snapshot options.
     */
    public function after(): array
    {
        return [function (Validator $validator) {
            if ($validator->errors()->isNotEmpty()) {
                return;
            }

            /** @var Attempt $attempt */
            $attempt = $this->route('attempt');
            $snapshot = $attempt->answers()->where('question_id', $this->integer('question_id'))->value('snapshot');

            if ($snapshot === null) {
                $validator->errors()->add('question_id', __('validation.exists', ['attribute' => 'question_id']));

                return;
            }

            $optionIds = array_column($snapshot['options'] ?? [], 'id');

            if (! in_array($this->integer('option_id'), $optionIds, true)) {
                $validator->errors()->add('option_id', __('validation.exists', ['attribute' => 'option_id']));
            }
        }];
    }
}
