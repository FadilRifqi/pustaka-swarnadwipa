extends Node2D

@export var leaf_scene: PackedScene # Masukkan scene daun di sini via Inspector
@export var spawn_rate: float = 0.1 # Muncul setiap 0.5 detik

var timer: float = 0.0
var screen_width: float

func _ready() -> void:
	# Ambil lebar layar otomatis
	screen_width = get_viewport_rect().size.x

func _process(delta: float) -> void:
	timer -= delta
	
	if timer <= 0:
		spawn_leaf()
		timer = spawn_rate # Reset timer

func spawn_leaf() -> void:
	if not leaf_scene:
		return
		
	var leaf_instance = leaf_scene.instantiate()
	
	# Tentukan posisi X secara acak dari ujung kiri ke ujung kanan layar
	var random_x = randf_range(0, screen_width)
	
	# Posisi Y di atas layar sedikit (misal -50) agar tidak muncul tiba-tiba ("pop-in")
	leaf_instance.position = Vector2(random_x, -50)
	
	add_child(leaf_instance)
