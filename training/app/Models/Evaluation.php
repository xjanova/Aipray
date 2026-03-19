<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Evaluation extends Model
{
    protected $fillable = [
        'ai_model_id', 'eval_type', 'recognized_text', 'reference_text',
        'accuracy', 'wer', 'cer', 'latency_ms', 'audio_file', 'details',
    ];

    protected $casts = [
        'details' => 'array',
    ];

    public function aiModel(): BelongsTo
    {
        return $this->belongsTo(AiModel::class);
    }
}
