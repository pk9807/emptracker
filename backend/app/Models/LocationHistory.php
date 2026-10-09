<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LocationHistory extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'latitude',
        'longitude',
        'speed',
        'heading',
        'accuracy',
        'battery_level',
        'recorded_at',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'double',
            'longitude' => 'double',
            'speed' => 'double',
            'heading' => 'double',
            'accuracy' => 'double',
            'battery_level' => 'integer',
            'recorded_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
