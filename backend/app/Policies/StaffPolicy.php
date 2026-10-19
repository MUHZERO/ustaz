<?php

namespace App\Policies;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

/**
 * Day-to-day records the assistant handles: staff can read and act on them,
 * nobody creates them from the panel, only the teacher deletes.
 * One concrete policy per model extends this so Laravel can discover it.
 */
abstract class StaffPolicy
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
        return false;
    }

    public function update(User $user, Model $model): bool
    {
        return $user->isStaff();
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
