<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AudioSample extends Model
{
    protected $fillable = [
        'filename', 'original_name', 'file_path', 'category', 'label',
        'transcript', 'duration', 'sample_rate', 'format', 'file_size',
        'status', 'device_info', 'metadata',
    ];

    protected $casts = [
        'metadata' => 'array',
        'duration' => 'float',
    ];

    public function getDurationFormattedAttribute(): string
    {
        $seconds = (int) $this->duration;
        $minutes = intdiv($seconds, 60);
        $secs = $seconds % 60;
        return sprintf('%d:%02d', $minutes, $secs);
    }

    public function scopeLabeled($query)
    {
        return $query->where('status', 'labeled');
    }

    public function scopeVerified($query)
    {
        return $query->where('status', 'verified');
    }

    public function scopeCategory($query, string $category)
    {
        return $query->where('category', $category);
    }
}
