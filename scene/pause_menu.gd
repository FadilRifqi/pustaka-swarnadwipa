extends CanvasLayer

var player: Player
const SAVE_PATH = "user://savegame.json"

# --- REFERENSI UNTUK SPAWN MUSUH ---
@export var skeleton_scene: PackedScene = preload("res://skeletonlvl1.tscn")
@export var kronco_scene: PackedScene = preload("res://orangpendek.tscn")

# Node Level (Parent dari PauseMenu) untuk tempat spawn musuh & cari BGM
@onready var level_node = get_parent() 

func _ready() -> void:
	visible = false 
	
	# Cek apakah kita barusan balik dari Settings?
	if Global.is_returning_from_settings:
		print(">> Kembali dari Settings, memulihkan kondisi...")
		Global.is_returning_from_settings = false
		
		# Tunggu frame agar tree stabil
		await get_tree().process_frame 
		
		# Load data total
		load_game() 
		
		# Pause game lagi
		get_tree().paused = true
		visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused
	
	if is_paused:
		update_player_reference()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update_player_reference() -> void:
	# Cari via Group
	player = get_tree().get_first_node_in_group("Player")
	
	# Fallback: Cari via Parent
	if not player:
		player = level_node.get_node_or_null("Player")

# --- SAVE GAME (LENGKAP) ---
func save_game() -> void:
	if not player: update_player_reference()
	if not player: return

	# 1. Ambil Data Kamera (Zoom & Offset)
	var cam_zoom_x = 1.0
	var cam_zoom_y = 1.0
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		cam_zoom_x = camera.zoom.x
		cam_zoom_y = camera.zoom.y

	# 2. Ambil Data Semua Musuh Aktif
	var enemies_data = []
	var active_enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			var type = ""
			if enemy is SkeletonLvl1: type = "skeleton"
			elif enemy is Kronco: type = "kronco"
			
			if type != "":
				enemies_data.append({
					"type": type,
					"pos_x": enemy.global_position.x,
					"pos_y": enemy.global_position.y,
					"health": enemy.health
				})

	# 3. Ambil Waktu BGM (Musik)
	var bgm_time = 0.0
	var bgm_node = level_node.get_node_or_null("bgm") # Pastikan nama node audio di Level adalah "bgm"
	if bgm_node and bgm_node.playing:
		bgm_time = bgm_node.get_playback_position()

	# 4. Struktur Data JSON
	var save_data = {
		"player": {
			"pos_x": player.global_position.x,
			"pos_y": player.global_position.y,
			"health": player.health,
			"weapon": player.weapon,
			"cam_zoom_x": cam_zoom_x,
			"cam_zoom_y": cam_zoom_y
		},
		"enemies": enemies_data,
		"bgm_time": bgm_time,
		"scene": get_tree().current_scene.scene_file_path
	}
	
	# 5. Tulis File
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game Tersimpan! (Time: ", bgm_time, "s)")

# --- LOAD GAME (LENGKAP) ---
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("File save tidak ada")
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	if data == null: return

	if not player: update_player_reference()

	# --- A. LOAD PLAYER & CAMERA ---
	if player and data.has("player"):
		var p_data = data["player"]
		
		# Load Posisi & Status
		player.global_position = Vector2(p_data["pos_x"], p_data["pos_y"])
		player.health = int(p_data["health"])
		player.weapon = p_data.get("weapon", "pedang")
		
		player.update_hearts()
		player.state = player.weapon + "_idle"
		player.UpdateAnimation()
		
		# FIX CAMERA POSISI TENGAH
		var camera = player.get_node_or_null("Camera2D")
		if camera:
			# Restore Zoom
			camera.zoom = Vector2(p_data["cam_zoom_x"], p_data["cam_zoom_y"])
			
			# Reset Posisi Relatif (Biar nempel di Player)
			camera.position = Vector2.ZERO
			camera.offset = Vector2.ZERO
			camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
			
			# Paksa Kamera Teleport (Anti-Lagging)
			camera.reset_smoothing()
			camera.force_update_scroll()

	# --- B. LOAD MUSUH (RESPAWN) ---
	if data.has("enemies"):
		# Hapus musuh lama
		var old_enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in old_enemies:
			enemy.queue_free()
		
		# Spawn musuh baru
		var enemies_list = data["enemies"]
		for e_data in enemies_list:
			var new_enemy
			if e_data["type"] == "skeleton": new_enemy = skeleton_scene.instantiate()
			elif e_data["type"] == "kronco": new_enemy = kronco_scene.instantiate()
			
			if new_enemy:
				new_enemy.position = Vector2(e_data["pos_x"], e_data["pos_y"])
				level_node.add_child(new_enemy)
				new_enemy.health = int(e_data["health"])

	# --- C. LOAD BGM ---
	if data.has("bgm_time"):
		var saved_time = float(data["bgm_time"])
		var bgm_node = level_node.get_node_or_null("bgm")
		if bgm_node:
			bgm_node.play(saved_time)

	print("Game Loaded!")
	
	if not Global.is_returning_from_settings:
		toggle_pause()

# --- TOMBOL UI ---
func _on_resume_pressed() -> void:
	toggle_pause()

func _on_save_pressed() -> void:
	save_game()

func _on_settings_pressed() -> void:
	save_game() # Auto save sebelum pindah scene
	Global.previous_scene = get_tree().current_scene.scene_file_path
	Global.is_returning_from_settings = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://setting.tscn")

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/MainMenu.tscn")
