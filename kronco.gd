class_name Kronco
extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var idle: Sprite2D = $Idle

@onready var player: Player = $"../Player"
@export var move_speed: float = 100.0
@export var gravity: float = 980.0
@export var chase_distance: float = 600.0

func _process(delta: float) -> void:
	if not player:
		print(player)
		return

	var distance = global_position.distance_to(player.global_position)

	# Ubah animasi sesuai kondisi
	if distance <= chase_distance:
		animation_player.play("idle")
	else:
		animation_player.play("idle")

func _physics_process(delta: float) -> void:
	if not player:
		return

	# Gravitasi
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Gerak horizontal (chase)
	var distance = global_position.distance_to(player.global_position)
	if distance <= chase_distance:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)

	move_and_slide()

	# Balik arah sprite sesuai pergerakan
	if velocity.x != 0:
		idle.flip_h = velocity.x > 0
