<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Shop extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'owner_name',
        'phone',
        'address',
        'latitude',
        'longitude',
        'geofence_radius_meters',
        'qr_code',
        'category',
        'status',
        'photo_url',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'double',
            'longitude' => 'double',
            'geofence_radius_meters' => 'integer',
        ];
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function assignedEmployees(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'employee_shops', 'shop_id', 'user_id')
                    ->withPivot('assigned_date', 'notes')
                    ->withTimestamps();
    }

    public function visits(): HasMany
    {
        return $this->hasMany(Visit::class, 'shop_id');
    }
}
