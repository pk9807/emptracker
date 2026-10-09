<?php

namespace Tests\Feature;

use App\AI\Services\AiGateway;
use App\AI\Services\AiPermissionService;
use App\AI\Services\ToolRegistry;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AiSecurityAndIsolationTest extends TestCase
{
    /**
     * Test 1: Admin can access all tools including search_employees
     */
    public function test_admin_has_access_to_all_tools(): void
    {
        $admin = User::where('role', 'admin')->first();
        if (!$admin) {
            $admin = User::create([
                'name' => 'Test Admin',
                'email' => 'testadmin@fieldforce.com',
                'password' => bcrypt('password'),
                'role' => 'admin',
                'is_active' => true,
            ]);
        }

        $response = $this->actingAs($admin, 'sanctum')->getJson('/api/ai/tools');
        $response->assertStatus(200);
        $response->assertJsonPath('data.user_role', 'admin');
        $this->assertEquals(10, $response->json('data.total_tools'));
    }

    /**
     * Test 2: Employee cannot see admin-only tools in tool registry
     */
    public function test_employee_cannot_see_admin_tools(): void
    {
        $employee = User::where('role', 'employee')->first();
        if (!$employee) {
            $employee = User::create([
                'name' => 'Test Employee',
                'email' => 'testemp@fieldforce.com',
                'password' => bcrypt('password'),
                'role' => 'employee',
                'is_active' => true,
            ]);
        }

        $response = $this->actingAs($employee, 'sanctum')->getJson('/api/ai/tools');
        $response->assertStatus(200);
        $response->assertJsonPath('data.user_role', 'employee');
        $this->assertEquals(9, $response->json('data.total_tools'));

        // Assert search_employees is not in the list
        $toolNames = array_column($response->json('data.tools'), 'name');
        $this->assertNotContains('search_employees', $toolNames);
    }

    /**
     * Test 3: Employee queries their own route and attendance safely
     */
    public function test_employee_can_query_own_route(): void
    {
        $employee = User::where('role', 'employee')->first();
        $response = $this->actingAs($employee, 'sanctum')->postJson('/api/ai/chat', [
            'message' => 'Mere aaj kitne shops pending hain?',
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('status', 'success');
        $response->assertJsonPath('data.type', 'answer');
        $this->assertContains('get_today_route', $response->json('data.tools_used'));
    }

    /**
     * Test 4: Health endpoint returns correct configuration
     */
    public function test_ai_health_endpoint(): void
    {
        $response = $this->getJson('/api/ai/health');
        $response->assertStatus(200);
        $response->assertJsonPath('data.ai_enabled', true);
    }
}
