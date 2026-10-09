<?php

namespace App\Providers;

use App\AI\Contracts\AiAuditServiceInterface;
use App\AI\Contracts\AiProviderInterface;
use App\AI\Contracts\LocalInferenceEngineInterface;
use App\AI\Providers\CloudAiProvider;
use App\AI\Providers\Engines\QwenLocalInferenceEngine;
use App\AI\Providers\LocalAiProvider;
use App\AI\Services\AiAuditService;
use App\AI\Services\AiContextBuilder;
use App\AI\Services\AiGateway;
use App\AI\Services\AiPermissionService;
use App\AI\Services\AiResponseValidator;
use App\AI\Services\AiRouter;
use App\AI\Services\ToolRegistry;
use App\AI\Services\AiConfirmationService;
use App\AI\Services\MapIntelligenceService;
use App\AI\Tools\Map\GetAreaCoverageSummaryTool;
use App\AI\Tools\Map\GetEmployeeRouteSummaryTool;
use App\AI\Tools\Map\GetNextShopRecommendationTool;
use App\AI\Tools\Map\GetOverdueShopsTool;
use App\AI\Tools\ReadOnly\GetEmployeeAttendanceTool;
use App\AI\Tools\ReadOnly\GetEmployeeLocationTool;
use App\AI\Tools\ReadOnly\GetEmployeeProfileTool;
use App\AI\Tools\ReadOnly\GetEmployeeVisitsTool;
use App\AI\Tools\ReadOnly\GetNearbyShopsTool;
use App\AI\Tools\ReadOnly\GetShopDetailsTool;
use App\AI\Tools\ReadOnly\GetShopVisitsTool;
use App\AI\Tools\ReadOnly\GetTodayRouteTool;
use App\AI\Tools\ReadOnly\SearchEmployeesTool;
use App\AI\Tools\ReadOnly\SearchShopsTool;
use App\AI\Tools\Write\AddShopUrgentNoteTool;
use App\AI\Tools\Write\AssignEmployeeShopTool;
use App\AI\Tools\Write\RecordVisitRemarkTool;
use App\AI\Services\AiSignalDetector;
use App\AI\Services\AiInsightEngine;
use App\AI\Tools\Proactive\GetProactiveInsightsTool;
use App\AI\Tools\Proactive\GetDailyOperationalSummaryTool;
use Illuminate\Support\ServiceProvider;

class AiServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Bind Singletons
        $this->app->singleton(LocalInferenceEngineInterface::class, fn() => new QwenLocalInferenceEngine());
        $this->app->singleton(AiPermissionService::class, fn() => new AiPermissionService());
        $this->app->singleton(AiConfirmationService::class, fn() => new AiConfirmationService());
        $this->app->singleton(MapIntelligenceService::class, fn() => new MapIntelligenceService());
        $this->app->singleton(AiSignalDetector::class, fn() => new AiSignalDetector());
        $this->app->singleton(AiInsightEngine::class, fn($app) => new AiInsightEngine($app->make(AiSignalDetector::class)));
        $this->app->singleton(AiAuditServiceInterface::class, fn() => new AiAuditService());
        $this->app->singleton(AiContextBuilder::class, fn() => new AiContextBuilder());
        $this->app->singleton(AiResponseValidator::class, fn() => new AiResponseValidator());
        $this->app->singleton(\App\AI\Services\AiModelRegistry::class, fn() => new \App\AI\Services\AiModelRegistry());
        $this->app->singleton(\App\AI\Services\AiDataSanitizer::class, fn() => new \App\AI\Services\AiDataSanitizer());
        $this->app->singleton(\App\AI\Services\LanguageDetectionService::class, fn() => new \App\AI\Services\LanguageDetectionService());
        $this->app->singleton(\App\AI\Services\OfflineCapabilityService::class, fn() => new \App\AI\Services\OfflineCapabilityService());
        $this->app->singleton(LocalAiProvider::class, fn($app) => new LocalAiProvider($app->make(LocalInferenceEngineInterface::class)));
        $this->app->singleton(CloudAiProvider::class, fn() => new CloudAiProvider());


        // Register and Populate Tool Registry
        $this->app->singleton(ToolRegistry::class, function ($app) {
            $permissionService = $app->make(AiPermissionService::class);
            $mapService = $app->make(MapIntelligenceService::class);
            $insightEngine = $app->make(AiInsightEngine::class);
            $registry = new ToolRegistry($permissionService);

            // Register all read-only foundation tools
            $registry->registerTool(new SearchEmployeesTool($permissionService));
            $registry->registerTool(new GetEmployeeProfileTool($permissionService));
            $registry->registerTool(new GetEmployeeLocationTool($permissionService));
            $registry->registerTool(new GetEmployeeAttendanceTool($permissionService));
            $registry->registerTool(new GetEmployeeVisitsTool($permissionService));
            $registry->registerTool(new SearchShopsTool($permissionService));
            $registry->registerTool(new GetShopDetailsTool($permissionService));
            $registry->registerTool(new GetShopVisitsTool($permissionService));
            $registry->registerTool(new GetNearbyShopsTool($permissionService));
            $registry->registerTool(new GetTodayRouteTool($permissionService));

            // Register Phase 4 safe write tools
            $registry->registerTool(new AssignEmployeeShopTool());
            $registry->registerTool(new AddShopUrgentNoteTool());
            $registry->registerTool(new RecordVisitRemarkTool());

            // Register Phase 5 Map Intelligence tools
            $registry->registerTool(new GetOverdueShopsTool($permissionService, $mapService));
            $registry->registerTool(new GetNextShopRecommendationTool($permissionService, $mapService));
            $registry->registerTool(new GetEmployeeRouteSummaryTool($permissionService, $mapService));
            $registry->registerTool(new GetAreaCoverageSummaryTool($permissionService, $mapService));

            // Register Phase 7 Proactive Intelligence tools
            $registry->registerTool(new GetProactiveInsightsTool($permissionService, $insightEngine));
            $registry->registerTool(new GetDailyOperationalSummaryTool($permissionService, $insightEngine));

            return $registry;
        });

        // Register Router and Gateway
        $this->app->singleton(AiRouter::class, function ($app) {
            return new AiRouter(
                $app->make(ToolRegistry::class),
                $app->make(LocalAiProvider::class),
                $app->make(CloudAiProvider::class)
            );
        });

        $this->app->singleton(AiGateway::class, function ($app) {
            return new AiGateway(
                $app->make(ToolRegistry::class),
                $app->make(AiRouter::class),
                $app->make(AiContextBuilder::class),
                $app->make(AiResponseValidator::class),
                $app->make(AiAuditServiceInterface::class),
                $app->make(AiPermissionService::class),
                $app->make(AiConfirmationService::class)
            );
        });
    }

    public function boot(): void
    {
        //
    }
}

