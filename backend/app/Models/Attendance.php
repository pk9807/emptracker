<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Attendance extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'date',
        'check_in_time',
        'check_out_time',
        'check_in_lat',
        'check_in_lng',
        'check_in_address',
        'check_out_lat',
        'check_out_lng',
        'check_out_address',
        'check_in_photo_url',
        'check_out_photo_url',
        'battery_level',
        'total_distance_km',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'check_in_time' => 'datetime',
            'check_out_time' => 'datetime',
            'check_in_lat' => 'double',
            'check_in_lng' => 'double',
            'check_out_lat' => 'double',
            'check_out_lng' => 'double',
            'total_distance_km' => 'double',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
