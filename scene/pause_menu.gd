extends CanvasLayer

var player: Player
const SAVE_PATH = "user://savegame.json"

# --- REFERENSI UNTUK SPAWN MUSUH ---
@export var skeleton_scene: PackedScene
@export var demon_scene: PackedScene 
@onready var save_toast: PanelContainer = $Control/SaveToast
@export var cindaku_scene: PackedScene 
@export var beguganjang_scene: PackedScene
@onready var level_node = get_parent() 

func _ready() -> void:
	visible = false 
	
	if Global.is_returning_from_settings:
		print(">> Kembali dari Settings, memulihkan kondisi...")
		Global.is_returning_from_settings = true
		await get_tree().process_frame 
		load_game() 
		get_tree().paused = true
		visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif Global.load_saved_game:
		print(">> Continue Game Detected! Loading data...")
		
		# Reset flag biar gak load terus menerus
		Global.load_saved_game = false
		
		# Tunggu 1 frame agar Player dan Level siap dulu
		await get_tree().process_frame 
		
		# Panggil fungsi load_game() yang ada di script ini
		# Fungsi inilah yang akan menempatkan Player, Musuh, dan Kamera
		load_game()
		
		# Kalau Continue, game JANGAN di-pause (langsung main)
		get_tree().paused = false
		visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func show_save_toast() -> void:
	# 1. Reset kondisi awal (Munculkan & Solid)
	save_toast.modulate.a = 1.0 
	save_toast.show()
	
	# 2. Buat Tween untuk animasi
	var tween = create_tween()
	
	# 3. Diam selama 2 detik
	tween.tween_interval(2.0)
	
	# 4. Fade Out (Menghilang pelan-pelan dalam 0.5 detik)
	tween.tween_property(save_toast, "modulate:a", 0.0, 0.5)
	
	# 5. Sembunyikan node setelah animasi selesai (biar rapi)
	tween.tween_callback(save_toast.hide)

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
	player = get_tree().get_first_node_in_group("Player")
	if not player:
		player = level_node.get_node_or_null("Player")

# --- SAVE GAME ---
func save_game() -> void:
	if not player: update_player_reference()
	if not player: return

	# 1. Data Kamera
	var cam_zoom_x = 1.0
	var cam_zoom_y = 1.0
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		cam_zoom_x = camera.zoom.x
		cam_zoom_y = camera.zoom.y

	# 2. Data Musuh
	var enemies_data = []
	var active_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			var type = ""
			if enemy is SkeletonLvl1: type = "skeleton"
			elif enemy is Demon: type = "demon"
			elif enemy is Cindaku: type = "cindaku"       # Tambahan
			elif enemy is BeguGanjang: type = "beguganjang" # Tambahan
			
			
			if type != "":
				enemies_data.append({
					"type": type,
					"pos_x": enemy.global_position.x,
					"pos_y": enemy.global_position.y,
					"health": enemy.health
				})

	# --- 3. DATA BGM (BARU) ---
	var bgm_time = 0.0
	# Pastikan nama node musik di level kamu adalah "bgm"
	var bgm_node = level_node.get_node_or_null("bgm")
	bgm_time = bgm_node.get_playback_position()
	
	var inventory_list = []
	# Akses node inventory via player (sesuaikan nama variabel di player.gd)
	if player.inventory_item: 
		inventory_list = player.inventory_item.get_save_data()

	# 4. Simpan JSON
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
		"bgm_time": bgm_time, # Simpan ke file
		"scene": get_tree().current_scene.scene_file_path,
		"visited_triggers": Global.visited_triggers,
		"unlocked_weapons": Global.unlocked_weapons,
		"inventory": inventory_list
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		show_save_toast()

# --- LOAD GAME ---
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	if data == null: return

	if not player: update_player_reference()

	# A. LOAD PLAYER & CAMERA
	if player and data.has("player"):
		var p_data = data["player"]
		player.global_position = Vector2(p_data["pos_x"], p_data["pos_y"])
		player.health = int(p_data["health"])
		player.weapon = p_data.get("weapon", "pedang")
		
		player.update_hearts()
		player.state = player.weapon + "_idle"
		player.UpdateAnimation()
		
		var camera = player.get_node_or_null("Camera2D")
		if camera:
			camera.zoom = Vector2(p_data["cam_zoom_x"], p_data["cam_zoom_y"])
			camera.reset_smoothing()
			camera.force_update_scroll()

	# B. LOAD MUSUH
	if data.has("enemies"):
		var old_enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in old_enemies: enemy.queue_free()
		
		for e_data in data["enemies"]:
			var new_enemy
			if e_data["type"] == "skeleton": new_enemy = skeleton_scene.instantiate()
			elif e_data["type"] == "demon": new_enemy = demon_scene.instantiate()
			elif e_data["type"] == "cindaku": new_enemy = cindaku_scene.instantiate()         # Tambahan
			elif e_data["type"] == "beguganjang": new_enemy = beguganjang_scene.instantiate() # Tambahan
			
			if new_enemy:
				new_enemy.position = Vector2(e_data["pos_x"], e_data["pos_y"])
				level_node.add_child(new_enemy)
				new_enemy.health = int(e_data["health"])

	# --- C. LOAD BGM (BARU) ---
	if data.has("bgm_time"):
		var saved_time = float(data["bgm_time"])
		var bgm_node = level_node.get_node_or_null("bgm")
		if bgm_node:
			# Play dari detik yang disimpan
			bgm_node.play(saved_time)
			# Kembalikan volume (jika sebelumnya di fade-in dari -80)
			bgm_node.volume_db = -10.0 # Sesuaikan dengan volume standar game kamu (misal -10 atau 0)
	
	if data.has("visited_triggers"):
		Global.visited_triggers = data["visited_triggers"]
		
		# Cari semua TextTrigger di level ini dan paksa cek ulang
		# (Asumsi TextTrigger punya nama class_name TextTrigger, atau kita cari by filename)
		# Cara manual cari node:
		var triggers = level_node.find_children("*", "Area2D", true, false)
		for t in triggers:
			# Cek apakah node ini punya variabel 'trigger_id' (berarti dia TextTrigger)
			if "trigger_id" in t:
				if t.trigger_id in Global.visited_triggers:
					t.queue_free()
	
	if data.has("unlocked_weapons"):
		Global.unlocked_weapons = data["unlocked_weapons"]
		# Penting: Beritahu player untuk update visual slotnya setelah data di-load
		if player:
			player.check_weapon_unlocks()
	
	if data.has("inventory"):
		var saved_inv = data["inventory"]
		
		# Pastikan variabel inventory_item di player valid
		if player.inventory_item:
			player.inventory_item.load_save_data(saved_inv)
			
			# Reset item yang sedang dipegang player (biar gak ngebug pegang item hantu)
			player.selected_item = null
			if player.item_slot_icon:
				player.item_slot_icon.texture = null
	
	print("Game Loaded & Music Resumed at: ", data.get("bgm_time", 0))
	
	if not Global.is_returning_from_settings:
		toggle_pause()

# --- TOMBOL ---
func _on_resume_pressed() -> void: toggle_pause()
func _on_save_pressed() -> void: save_game()
func _on_settings_pressed() -> void:
	save_game()
	Global.previous_scene = get_tree().current_scene.scene_file_path
	Global.is_returning_from_settings = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://setting.tscn")
func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/MainMenu.tscn")
