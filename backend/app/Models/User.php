<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'phone',
        'employee_code',
        'designation',
        'department',
        'avatar',
        'is_active',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_active' => 'boolean',
        ];
    }

    public function liveLocation(): HasOne
    {
        return $this->hasOne(LiveLocation::class, 'user_id');
    }

    public function locationHistories(): HasMany
    {
        return $this->hasMany(LocationHistory::class, 'user_id');
    }

    public function attendances(): HasMany
    {
        return $this->hasMany(Attendance::class, 'user_id');
    }

    public function visits(): HasMany
    {
        return $this->hasMany(Visit::class, 'user_id');
    }

    public function shops(): BelongsToMany
    {
        return $this->belongsToMany(Shop::class, 'employee_shops', 'user_id', 'shop_id')
                    ->withPivot('assigned_date', 'notes')
                    ->withTimestamps();
    }
}
