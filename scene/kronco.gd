class_name KroncoMainMenu
extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var idle: Sprite2D = $Idle

@export var move_speed: float = 100.0
@export var gravity: float = 980.0
@export var patrol_interval: float = 5.0   # ganti arah tiap 5 detik

var direction := 1                         # 1 = kanan, -1 = kiri
var timer := 0.0

func _ready() -> void:
	animation_player.play("idle")

func _process(delta: float) -> void:
	# Hitung waktu untuk ganti arah
	timer += delta
	if timer >= patrol_interval:
		direction *= -1  # balik arah
		timer = 0.0

func _physics_process(delta: float) -> void:
	# Gravitasi
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Gerak kiri–kanan otomatis
	velocity.x = direction * move_speed

	var collision = move_and_slide()

	# Jika menabrak dinding (barrier), balik arah
	if get_last_slide_collision() != null:
		direction *= -1

	# Flip sprite
	if velocity.x != 0:
		idle.flip_h = velocity.x > 0
