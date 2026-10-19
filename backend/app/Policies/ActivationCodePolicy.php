<?php

namespace App\Policies;

use App\Models\User;

final class ActivationCodePolicy extends StaffPolicy
{
    public function create(User $user): bool
    {
        return $user->isStaff();
    }
}
