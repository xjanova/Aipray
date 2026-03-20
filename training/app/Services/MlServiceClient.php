<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class MlServiceClient
{
    private string $baseUrl;
    private string $secret;
    private int $timeout;

    public function __construct()
    {
        $this->baseUrl = rtrim(config('services.ml.url', 'http://localhost:8100'), '/');
        $this->secret = config('services.ml.secret', 'ml-service-secret-key');
        $this->timeout = (int) config('services.ml.timeout', 300);
    }

    /**
     * Check if ML service is available.
     */
    public function isHealthy(): bool
    {
        try {
            $response = Http::timeout(5)->get("{$this->baseUrl}/health");
            return $response->ok() && $response->json('status') === 'ok';
        } catch (\Exception $e) {
            Log::warning('ML service health check failed: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Get ML service health info.
     */
    public function health(): ?array
    {
        try {
            $response = Http::timeout(5)->get("{$this->baseUrl}/health");
            return $response->ok() ? $response->json() : null;
        } catch (\Exception $e) {
            return null;
        }
    }

    /**
     * Start a training job on the ML service.
     */
    public function startTraining(array $params): array
    {
        $response = Http::timeout($this->timeout)
            ->withToken($this->secret)
            ->post("{$this->baseUrl}/train/start", $params);

        if (!$response->ok()) {
            throw new \RuntimeException("ML training start failed: " . $response->body());
        }

        return $response->json();
    }

    /**
     * Pause a training job.
     */
    public function pauseTraining(int $jobId): array
    {
        $response = Http::timeout(30)
            ->withToken($this->secret)
            ->post("{$this->baseUrl}/train/{$jobId}/pause");

        return $response->json() ?? ['message' => 'Request sent'];
    }

    /**
     * Cancel a training job.
     */
    public function cancelTraining(int $jobId): array
    {
        $response = Http::timeout(30)
            ->withToken($this->secret)
            ->post("{$this->baseUrl}/train/{$jobId}/cancel");

        return $response->json() ?? ['message' => 'Request sent'];
    }

    /**
     * Transcribe audio file.
     */
    public function transcribeFile(string $filePath, string $modelId = 'default'): array
    {
        $response = Http::timeout($this->timeout)
            ->withToken($this->secret)
            ->asMultipart()
            ->post("{$this->baseUrl}/transcribe/path", [
                ['name' => 'file_path', 'contents' => $filePath],
                ['name' => 'model_id', 'contents' => $modelId],
                ['name' => 'language', 'contents' => 'th'],
            ]);

        if (!$response->ok()) {
            throw new \RuntimeException("Transcription failed: " . $response->body());
        }

        return $response->json();
    }

    /**
     * Transcribe uploaded audio.
     */
    public function transcribeUpload($file, string $modelId = 'default'): array
    {
        $response = Http::timeout($this->timeout)
            ->attach('audio', file_get_contents($file->getRealPath()), $file->getClientOriginalName())
            ->post("{$this->baseUrl}/transcribe/file", [
                'model_id' => $modelId,
                'language' => 'th',
            ]);

        if (!$response->ok()) {
            throw new \RuntimeException("Transcription failed: " . $response->body());
        }

        return $response->json();
    }

    /**
     * Evaluate audio against reference text.
     */
    public function evaluate($audioFile, string $referenceText, string $modelId = 'default'): array
    {
        $response = Http::timeout($this->timeout)
            ->withToken($this->secret)
            ->attach('audio', file_get_contents($audioFile->getRealPath()), $audioFile->getClientOriginalName())
            ->post("{$this->baseUrl}/evaluate", [
                'reference_text' => $referenceText,
                'model_id' => $modelId,
            ]);

        if (!$response->ok()) {
            throw new \RuntimeException("Evaluation failed: " . $response->body());
        }

        return $response->json();
    }

    /**
     * Load a model on the ML service.
     */
    public function loadModel(string $modelPath, string $modelId = 'default'): array
    {
        $response = Http::timeout(120)
            ->withToken($this->secret)
            ->asMultipart()
            ->post("{$this->baseUrl}/models/load", [
                ['name' => 'model_path', 'contents' => $modelPath],
                ['name' => 'model_id', 'contents' => $modelId],
            ]);

        return $response->json() ?? [];
    }

    /**
     * Get available models from ML service.
     */
    public function getModels(): array
    {
        try {
            $response = Http::timeout(10)->get("{$this->baseUrl}/models");
            return $response->ok() ? $response->json() : [];
        } catch (\Exception $e) {
            return [];
        }
    }

    /**
     * Export model to ONNX format.
     */
    public function exportOnnx(string $modelPath, ?string $outputPath = null): array
    {
        $response = Http::timeout(600)
            ->withToken($this->secret)
            ->asMultipart()
            ->post("{$this->baseUrl}/models/export-onnx", array_filter([
                ['name' => 'model_path', 'contents' => $modelPath],
                $outputPath ? ['name' => 'output_path', 'contents' => $outputPath] : null,
            ]));

        if (!$response->ok()) {
            throw new \RuntimeException("ONNX export failed: " . $response->body());
        }

        return $response->json();
    }
}
