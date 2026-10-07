<?php

namespace Tests\Feature;

use App\Models\Meter;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EnergyApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_registration_creates_an_account_and_api_token(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Asha Mushi',
            'email' => 'asha@example.com',
            'password' => 'a-secure-password',
            'password_confirmation' => 'a-secure-password',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.user.name', 'Asha Mushi')
            ->assertJsonStructure(['data' => ['user' => ['id', 'email'], 'token']]);
        $this->assertDatabaseHas('users', ['email' => 'asha@example.com']);
    }

    public function test_meter_records_and_transfers_are_account_scoped_and_persisted(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');

        $home = $this->postJson('/api/meters', [
            'name' => 'Home',
            'number' => '100-200',
            'kind' => 'home',
            'balanceKwh' => 100.5,
        ])->assertCreated()->assertJsonPath('data.status', 'pending');

        $office = $this->postJson('/api/meters', [
            'name' => 'Office',
            'number' => '300-400',
            'kind' => 'business',
            'balanceKwh' => 15,
        ])->assertCreated();

        $transfer = $this->postJson('/api/transfers', [
            'fromMeterId' => $home->json('data.id'),
            'toMeterId' => $office->json('data.id'),
            'amountKwh' => 12.25,
        ])->assertCreated()
            ->assertJsonPath('data.transfer.amountKwh', 12.25)
            ->assertJsonPath('data.transfer.fromMeterName', 'Home')
            ->assertJsonPath('data.meters.0.id', $home->json('data.id'))
            ->assertJsonStructure([
                'data' => [
                    'transfer' => ['id', 'createdAt'],
                    'meters',
                ],
            ]);

        $this->assertDatabaseHas('meters', [
            'id' => $home->json('data.id'),
            'balance_kwh' => '88.250',
        ]);
        $this->assertDatabaseHas('meters', [
            'id' => $office->json('data.id'),
            'balance_kwh' => '27.250',
        ]);
        $this->assertDatabaseHas('energy_transfers', [
            'reference' => $transfer->json('data.transfer.id'),
            'user_id' => $user->id,
            'amount_kwh' => '12.250',
        ]);

        $this->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonCount(2, 'data.meters')
            ->assertJsonCount(1, 'data.transfers');
    }

    public function test_transfer_rejects_another_users_meter_without_changing_balances(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $source = Meter::create([
            'user_id' => $user->id,
            'name' => 'My home',
            'number' => 'my-meter',
            'kind' => 'home',
            'balance_kwh' => 50,
            'status' => 'pending',
        ]);
        $otherMeter = Meter::create([
            'user_id' => $otherUser->id,
            'name' => 'Other home',
            'number' => 'other-meter',
            'kind' => 'home',
            'balance_kwh' => 50,
            'status' => 'pending',
        ]);

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/transfers', [
                'fromMeterId' => $source->id,
                'toMeterId' => $otherMeter->id,
                'amountKwh' => 10,
            ])
            ->assertUnprocessable();

        $this->assertDatabaseHas('meters', [
            'id' => $source->id,
            'balance_kwh' => '50.000',
        ]);
        $this->assertDatabaseCount('energy_transfers', 0);
    }

    public function test_private_energy_routes_require_authentication(): void
    {
        $this->getJson('/api/dashboard')->assertUnauthorized();
        $this->get('/api/dashboard')->assertUnauthorized();
        $this->postJson('/api/meters', [])->assertUnauthorized();
    }
}
