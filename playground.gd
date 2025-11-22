extends Node2D

# --- SETUP DI INSPECTOR ---
@export var skeleton_scene: PackedScene = preload("res://skeletonlvl1.tscn")
@export var kronco_scene: PackedScene = preload("res://orangpendek.tscn")

# Konfigurasi Jumlah Spawn
@export var min_spawn: int = 5
@export var max_spawn: int = 10

# Audio
@onready var bgm: AudioStreamPlayer = $bgm
@export var target_volume: float = 7.0 
@export var fade_duration: float = 2.0

# Konfigurasi Area Spawn (Batas Level)
@export var spawn_area_min: Vector2 = Vector2(-1600, 400)
@export var spawn_area_max: Vector2 = Vector2(1600, 400)

# --- PENGATURAN JARAK ---
@export var safe_distance: float = 400.0 # Jarak minimal antar musuh
@export var spawn_buffer_from_player: float = 400.0 # Jarak minimal dari Player

# --- PERBAIKAN POSISI SKELETON ---
# Jika skeleton tenggelam, ubah angka ini (misal -20, -50) untuk menaikkannya
@export var skeleton_y_offset: float = 0.0 

# Referensi Player
@onready var player: Player = $Player

func _ready() -> void:
	fade_in_music()    
	spawn_enemies()

func fade_in_music() -> void:
	bgm.volume_db = -80.0
	bgm.play()
	var tween = create_tween()
	tween.tween_property(bgm, "volume_db", target_volume, fade_duration)

func spawn_enemies() -> void:
	if not skeleton_scene or not kronco_scene:
		print("Error: Scene belum dimasukkan!")
		return
	if not player:
		print("Error: Player tidak ditemukan!")
		return

	var total_enemies = randi_range(min_spawn, max_spawn)
	print("Mencoba spawn ", total_enemies, " musuh...")
	
	var existing_positions: Array[Vector2] = []
	
	for i in range(total_enemies):
		var enemy_instance
		var is_skeleton = false # Cek tipe musuh
		
		if randf() > 0.5:
			enemy_instance = skeleton_scene.instantiate()
			enemy_instance.name = "Skeleton_" + str(i)
			is_skeleton = true
		else:
			enemy_instance = kronco_scene.instantiate()
			enemy_instance.name = "Kronco_" + str(i)
		
		# --- LOGIKA MENCARI POSISI ---
		var final_position = Vector2.ZERO
		var position_found = false
		var attempts = 0
		var max_attempts = 100
		
		while attempts < max_attempts:
			attempts += 1
			
			var min_x = spawn_area_min.x
			var max_x = spawn_area_max.x
			
			# --- LOGIKA ARAH HADAP DENGAN FALLBACK ---
			if player.cardinal_direction == Vector2.RIGHT:
				# Coba spawn di KANAN player
				var try_min = max(spawn_area_min.x, player.position.x + spawn_buffer_from_player)
				var try_max = spawn_area_max.x
				
				# PERBAIKAN BUG 1: Jika di kanan penuh (mentok tembok), 
				# spawn di KIRI player (Belakang)
				if try_min >= try_max:
					min_x = spawn_area_min.x
					max_x = min(spawn_area_max.x, player.position.x - spawn_buffer_from_player)
				else:
					min_x = try_min
					max_x = try_max
					
			else: # Player hadap KIRI
				# Coba spawn di KIRI player
				var try_min = spawn_area_min.x
				var try_max = min(spawn_area_max.x, player.position.x - spawn_buffer_from_player)
				
				# PERBAIKAN BUG 1: Jika di kiri penuh, spawn di KANAN
				if try_min >= try_max:
					min_x = max(spawn_area_min.x, player.position.x + spawn_buffer_from_player)
					max_x = spawn_area_max.x
				else:
					min_x = try_min
					max_x = try_max

			# Acak Posisi
			var random_x = randf_range(min_x, max_x)
			var random_y = randf_range(spawn_area_min.y, spawn_area_max.y)
			
			# PERBAIKAN BUG 2: SKELETON DI BAWAH LANTAI
			# Jika musuhnya skeleton, kita naikkan posisinya (Y dikurangi)
			if is_skeleton:
				random_y += skeleton_y_offset
			
			var candidate_pos = Vector2(random_x, random_y)
			
			# Cek Overlap dengan musuh lain
			var too_close = false
			for existing_pos in existing_positions:
				if candidate_pos.distance_to(existing_pos) < safe_distance:
					too_close = true
					break 
			
			if not too_close:
				final_position = candidate_pos
				position_found = true
				break 
		
		# --- SPAWN ---
		if position_found:
			enemy_instance.position = final_position
			add_child(enemy_instance)
			existing_positions.append(final_position)
		else:
			print("Gagal spawn musuh ke-", i, " (Area Penuh)")
			enemy_instance.queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		print("Reset Musuh...")
		for child in get_children():
			# Jangan hapus Player atau BGM, hapus musuh saja
			if child.name.begins_with("Skeleton") or child.name.begins_with("Kronco"):
				child.queue_free()
		spawn_enemies()
