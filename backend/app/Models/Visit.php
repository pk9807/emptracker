<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Visit extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'shop_id',
        'check_in_time',
        'check_out_time',
        'check_in_lat',
        'check_in_lng',
        'check_out_lat',
        'check_out_lng',
        'photo_url',
        'signature_url',
        'notes',
        'purpose',
        'outcome',
        'order_amount',
        'is_verified_geofence',
        'distance_from_shop_meters',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'check_in_time' => 'datetime',
            'check_out_time' => 'datetime',
            'check_in_lat' => 'double',
            'check_in_lng' => 'double',
            'check_out_lat' => 'double',
            'check_out_lng' => 'double',
            'order_amount' => 'decimal:2',
            'is_verified_geofence' => 'boolean',
            'distance_from_shop_meters' => 'double',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class, 'shop_id');
    }
}
