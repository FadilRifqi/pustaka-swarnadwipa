extends Area2D

# --- SETUP DI INSPECTOR ---
@export_enum("rencong", "keris") var weapon_reward: String = "rencong"

# Referensi Node
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var margin_container: MarginContainer = $MarginContainer

@onready var raycast: RayCast2D = $RayCast2D # Node baru untuk deteksi tanah

# Logika Jatuh
var velocity_y: float = 0.0
var is_on_ground: bool = false

var is_opened: bool = false
var player_in_range: bool = false
var player_ref: Player = null

func _ready() -> void:
	animated_sprite.play("idle")
	margin_container.visible = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	# --- LOGIKA GRAVITASI MANUAL ---
	# Jika belum menyentuh tanah, jatuh ke bawah
	if not is_on_ground:
		velocity_y += gravity * delta
		position.y += velocity_y * delta
		
		# Cek apakah RayCast menyentuh tanah?
		if raycast.is_colliding():
			# Ambil titik tabrakan agar posisi peti pas di atas tanah
			var collision_point = raycast.get_collision_point()
			position.y = collision_point.y - (animated_sprite.sprite_frames.get_frame_texture("idle", 0).get_height() / 2.0 * scale.y) - 10
			# Atau sesuaikan offset manual jika posisi kurang pas:
			# position.y = collision_point.y - 15 
			
			is_on_ground = true
			velocity_y = 0

func _input(event: InputEvent) -> void:
	if player_in_range and not is_opened and event.is_action_pressed("interact"):
		open_chest()

func open_chest() -> void:
	if is_opened: return
	is_opened = true
	margin_container.visible = false
	
	# 1. Mainkan animasi buka
	animated_sprite.play("opened")
	
	# 2. Berikan Hadiah
	give_reward()
	
	# 3. --- EFEK MENGHILANG SETELAH DIBUKA ---
	# Tunggu sebentar (misal 1 detik) agar player sempat lihat petinya terbuka
	await get_tree().create_timer(1.5).timeout
	
	# Buat efek transparan pelan-pelan (Fade Out)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0) # Transparan dalam 1 detik
	
	# Tunggu animasi transparan selesai
	await tween.finished
	
	# Hapus Peti dari game
	queue_free()

func give_reward() -> void:
	if Global.unlocked_weapons[weapon_reward] == true:
		if player_ref:
			player_ref.add_money(50)
			player_ref.show_notification("Sudah punya! Dapat 50 Gold.")
	else:
		Global.unlocked_weapons[weapon_reward] = true
		if player_ref:
			player_ref.check_weapon_unlocks()
			player_ref.show_notification("Dapat Senjata: " + weapon_reward.capitalize() + "!")
			var pause_menu = get_tree().root.find_child("PauseMenu", true, false)
			if pause_menu: pause_menu.save_game()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = true
		player_ref = body
		if not is_opened: margin_container.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
		player_ref = null
		margin_container.visible = false
