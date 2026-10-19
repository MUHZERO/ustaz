<?php

use Illuminate\Database\Eloquent\Model;

it('responds on the health endpoint', function () {
    $this->get('/up')->assertOk();
});

it('throws on lazy loading outside production', function () {
    expect(Model::preventsLazyLoading())->toBeTrue();
});
