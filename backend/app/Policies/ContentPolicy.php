<?php

namespace App\Policies;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

/**
 * Teaching content: staff can read it, only the teacher can change it.
 * One concrete policy per model extends this so Laravel can discover it.
 */
abstract class ContentPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->isStaff();
    }

    public function view(User $user, Model $model): bool
    {
        return $user->isStaff();
    }

    public function create(User $user): bool
    {
        return $user->isTeacher();
    }

    public function update(User $user, Model $model): bool
    {
        return $user->isTeacher();
    }

    public function delete(User $user, Model $model): bool
    {
        return $user->isTeacher();
    }

    public function deleteAny(User $user): bool
    {
        return $user->isTeacher();
    }
}
