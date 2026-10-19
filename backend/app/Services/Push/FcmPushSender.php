<?php

namespace App\Services\Push;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

/**
 * Firebase Cloud Messaging HTTP v1 without an SDK: a service-account JWT is
 * exchanged for an OAuth token (cached), then one message is sent per token.
 */
final class FcmPushSender implements PushSender
{
    private const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    /**
     * @param  array{project_id: string, client_email: string, private_key: string, token_uri?: string}  $credentials
     */
    public function __construct(private readonly array $credentials) {}

    public function send(array $tokens, string $title, string $body, array $data = []): void
    {
        $url = "https://fcm.googleapis.com/v1/projects/{$this->credentials['project_id']}/messages:send";
        $accessToken = $this->accessToken();

        foreach ($tokens as $token) {
            Http::withToken($accessToken)->post($url, ['message' => [
                'token' => $token,
                'notification' => ['title' => $title, 'body' => $body],
                'data' => array_map('strval', $data),
            ]]);
        }
    }

    private function accessToken(): string
    {
        return Cache::remember('fcm-access-token:'.$this->credentials['client_email'], 3000, function () {
            return Http::asForm()->post($this->credentials['token_uri'] ?? 'https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $this->jwt(),
            ])->throw()->json('access_token');
        });
    }

    private function jwt(): string
    {
        $now = time();
        $encode = fn (array $part) => rtrim(strtr(base64_encode(json_encode($part)), '+/', '-_'), '=');
        $unsigned = $encode(['alg' => 'RS256', 'typ' => 'JWT']).'.'.$encode([
            'iss' => $this->credentials['client_email'],
            'scope' => self::SCOPE,
            'aud' => $this->credentials['token_uri'] ?? 'https://oauth2.googleapis.com/token',
            'iat' => $now,
            'exp' => $now + 3600,
        ]);

        openssl_sign($unsigned, $signature, $this->credentials['private_key'], OPENSSL_ALGO_SHA256);

        return $unsigned.'.'.rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');
    }
}
