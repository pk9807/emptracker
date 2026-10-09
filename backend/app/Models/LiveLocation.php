<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LiveLocation extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'latitude',
        'longitude',
        'accuracy',
        'speed',
        'heading',
        'altitude',
        'battery_level',
        'is_mocked',
        'activity_type',
        'is_online',
        'last_ping_at',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'double',
            'longitude' => 'double',
            'accuracy' => 'double',
            'speed' => 'double',
            'heading' => 'double',
            'altitude' => 'double',
            'battery_level' => 'integer',
            'is_mocked' => 'boolean',
            'is_online' => 'boolean',
            'last_ping_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
