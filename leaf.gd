extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Setting
var fall_speed: float = 100.0
var sway_amp: float = 50.0
var sway_speed: float = 2.0
var time: float = 0.0

func _ready() -> void:
	# Pastikan animasi jalan
	if animated_sprite:
		animated_sprite.play("default")
	
	# Acak parameter biar variatif
	fall_speed = randf_range(50.0, 150.0)
	sway_amp = randf_range(20.0, 80.0)
	sway_speed = randf_range(1.0, 3.0)
	time = randf_range(0.0, 10.0) # Biar gak sinkron
	
	# Acak ukuran & rotasi
	rotation_degrees = randf_range(0, 360)
	var scale_val = randf_range(0.5, 1.0)
	scale = Vector2(scale_val, scale_val)

func _process(delta: float) -> void:
	time += delta
	
	# 1. Gerak Jatuh ke Bawah (Ubah posisi Y langsung)
	position.y += fall_speed * delta
	
	# 2. Gerak Goyang Kiri-Kanan (Sinewave)
	# Kita tambahkan offset ke posisi X
	position.x += sin(time * sway_speed) * (sway_amp * delta)
	
	# 3. Putar daun
	rotation_degrees += (sway_speed * 10) * delta
	
	# 4. Hapus jika lewat batas bawah layar (Misal 800px)
	if position.y > 1000:
		queue_free()
