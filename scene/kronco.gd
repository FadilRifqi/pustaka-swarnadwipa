class_name KroncoMainMenu
extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var idle: Sprite2D = $Idle

@export var move_speed: float = 100.0
@export var gravity: float = 980.0
@export var patrol_interval: float = 5.0   # ganti arah tiap 5 detik

var direction := 1
var timer := 0.0

func _ready() -> void:
	animation_player.play("idle")

func _process(delta: float) -> void:
	timer += delta
	if timer >= patrol_interval:
		direction *= -1
		timer = 0.0

func _physics_process(delta: float) -> void:
	# Gravitasi
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Gerak kiri–kanan otomatis
	velocity.x = direction * move_speed

	move_and_slide()

	# Cek tabrakan terakhir
	var col = get_last_slide_collision()
	if col:
		var hit = col.get_collider()
		# Jangan balik arah kalau collider-nya StaticBody2D tertentu
		if hit.name != "StaticBody2D":
			direction *= -1

	# Flip sprite
	if velocity.x != 0:
		idle.flip_h = velocity.x > 0
