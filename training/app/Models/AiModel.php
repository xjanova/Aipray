<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AiModel extends Model
{
    protected $fillable = [
        'name', 'version', 'base_model', 'training_job_id', 'file_path',
        'file_size', 'accuracy', 'wer', 'cer', 'total_samples_trained',
        'total_hours_trained', 'eval_results', 'status', 'notes',
    ];

    protected $casts = [
        'eval_results' => 'array',
    ];

    public function trainingJob(): BelongsTo
    {
        return $this->belongsTo(TrainingJob::class);
    }

    public function evaluations(): HasMany
    {
        return $this->hasMany(Evaluation::class);
    }

    public function getFileSizeFormattedAttribute(): string
    {
        $bytes = $this->file_size;
        if ($bytes >= 1073741824) return round($bytes / 1073741824, 1) . ' GB';
        if ($bytes >= 1048576) return round($bytes / 1048576, 1) . ' MB';
        return round($bytes / 1024, 1) . ' KB';
    }
}
