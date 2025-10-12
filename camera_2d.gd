extends Camera2D

@export var player_path: NodePath
@export var freeze_while_airborne: bool = true     # true = kamera berhenti total saat di udara
@export var lock_vertical_only: bool = true        # true = hanya hentikan follow sumbu Y saat di udara

var player: CharacterBody2D
var was_on_floor: bool = true
var frozen_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	make_current()
	player = get_node_or_null(player_path)
	if player:
		was_on_floor = player.is_on_floor()
	frozen_position = global_position

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var on_floor := player.is_on_floor()

	# Simpan posisi kamera saat mulai melompat (keluar dari lantai)
	if was_on_floor and not on_floor:
		frozen_position = global_position
	was_on_floor = on_floor

	var target := player.global_position

	# Hentikan follow saat di udara
	if freeze_while_airborne and not on_floor:
		if lock_vertical_only:
			target.y = frozen_position.y     # stop follow Y; X tetap mengikuti
		else:
			target = frozen_position         # stop follow X dan Y

	# Biarkan smoothing bawaan Camera2D bekerja (aktifkan Position Smoothing di inspector)
	global_position = target
