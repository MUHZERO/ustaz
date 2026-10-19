<?php

it('responds on the health endpoint', function () {
    $this->get('/up')->assertOk();
});

it('throws on lazy loading outside production', function () {
    expect(\Illuminate\Database\Eloquent\Model::preventsLazyLoading())->toBeTrue();
});
