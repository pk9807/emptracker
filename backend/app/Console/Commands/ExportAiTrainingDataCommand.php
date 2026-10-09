<?php

namespace App\Console\Commands;

use App\AI\Services\AiTrainingPipelineService;
use Illuminate\Console\Command;

class ExportAiTrainingDataCommand extends Command
{
    protected $signature = 'ai:export-training-data 
                            {--format=alpaca : Export format (alpaca, sharegpt, lora)} 
                            {--output= : Target export output filepath}';

    protected $description = 'Export collected FieldForce conversational AI dataset for continuous local model fine-tuning';

    public function handle(AiTrainingPipelineService $trainingService): int
    {
        $format = $this->option('format') ?: 'alpaca';
        $output = $this->option('output');

        $this->info("Exporting continuous AI training dataset (format: {$format})...");

        $exportedFile = $trainingService->exportDataset($format, $output);

        if (empty($exportedFile) || !file_exists($exportedFile)) {
            $this->warn("No training interactions found to export.");
            return Command::SUCCESS;
        }

        $stats = $trainingService->getStats();
        $this->info("Dataset export completed successfully!");
        $this->line("• File: <comment>{$exportedFile}</comment>");
        $this->line("• Total Samples: <comment>{$stats['total_samples']}</comment>");
        $this->line("• Size: <comment>" . round($stats['file_size_bytes'] / 1024, 2) . " KB</comment>");

        return Command::SUCCESS;
    }
}
