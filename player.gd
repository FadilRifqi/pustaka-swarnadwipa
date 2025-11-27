class_name Player extends CharacterBody2D

# --- VARIABLES ---
# UPDATED: Array ini sekarang menyimpan AnimatedSprite2D langsung
var heart_list : Array[AnimatedSprite2D] 

# Health Logic: 3 Jantung x 5 Frame = 15 Total HP (Contoh)
var health : int = 12 
var max_hp_per_heart : int = 4 
var is_inventory_opened = false
var max_stamina : float = 10.0
var current_stamina : float = 10.0
var stamina_timer : float = 0.0
@onready var stamina_bar: ProgressBar = $HealthLayer/Stamina # Ganti nama variabel node
var regen_rate : float = 1.0 / 1.8
var cardinal_direction : Vector2 = Vector2.RIGHT
var direction : Vector2 = Vector2.ZERO
@export var move_speed : float = 300.0
@onready var attack_area: Area2D = $AttackArea
@onready var tutorial_bubble: PanelContainer = $TutorialBubble
@onready var label: Label = $TutorialBubble/Label
@onready var keris: Sprite2D = $HealthLayer/Keris
@onready var rencong: Sprite2D = $HealthLayer/Rencong
@onready var locked_rencong: Sprite2D = $HealthLayer/LockedRencong
@onready var locked_keris: Sprite2D = $HealthLayer/LockedKeris
@onready var inventory_item: TextureRect = $HealthLayer/InventoryItem 
@onready var item_slot_icon: Sprite2D = $HealthLayer/HealthPotion

var selected_item = null
# State & Weapon
var notification_tween: Tween
var state : String = "pedang_idle"
var weapon : String = "pedang"
var last_pressed : String = ""
var next_attack : String = ""
var is_attacking : bool = false

# Damage & Invincibility
var is_invincible : bool = false
var invincibility_duration : float = 1.0 

# Physics
var gravity : float = 5000
var jump_force : float = -1500
var is_jumping : bool = false
var coyote_time: float = 0.12
var jump_buffer_time: float = 0.12
var fall_gravity_multiplier: float = 2.0
var jump_cut_multiplier: float = 2.2
var apex_gravity_multiplier: float = 0.85
var apex_threshold: float = 120.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# Dash
var is_dashing: bool = false
var can_air_dash: bool = true
var dash_dir_x: int = 1
var dash_duration: float = 0.18
var dash_timer: float = 0.0
var is_hurt: bool = false

@export var knockback_force: float = 250.0 # Kekuatan terpental
@export var dash_speed: float = 900.0
@export var character_scale: float = 3.0 

@onready var animation_player: AnimationPlayer = $AnimationPlayer

# --- SPRITE NODES ---
@onready var keris_attack: Sprite2D = $KerisAttack
@onready var keris_idle: Sprite2D = $KerisIdle
@onready var keris_run: Sprite2D = $KerisRun
@onready var rencong_attack: Sprite2D = $RencongAttack
@onready var rencong_run: Sprite2D = $RencongRun
@onready var rencong_idle: Sprite2D = $RencongIdle
@onready var pedang_attack: Sprite2D = $PedangAttack
@onready var pedang_idle: Sprite2D = $PedangIdle
@onready var pedang_run: Sprite2D = $PedangRun

func _ready() -> void:
	var hearts_parent = $HealthLayer/HBoxContainer
	scale = Vector2(character_scale, character_scale)
	check_weapon_unlocks()
	
	if hearts_parent:
		for child in hearts_parent.get_children():
			# UPDATED: Cek apakah child adalah AnimatedSprite2D
			if child is AnimatedSprite2D:
				child.scale.x = -child.scale.x
				heart_list.append(child)
			
	# Setup Hitbox
	attack_area.monitoring = false
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)
	
	UpdateAnimation()
	update_hearts()
	update_stamina_ui()

func _process(delta: float) -> void:
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	if direction.x != 0:
		cardinal_direction = Vector2.RIGHT if direction.x > 0 else Vector2.LEFT
	if Input.is_action_just_pressed("jump"):
		if is_on_floor(): jump_buffer_timer = jump_buffer_time
		elif not is_attacking and not is_dashing and can_air_dash: _start_air_dash()
	if Input.is_action_just_pressed("inventory"):
		# Gunakan nama variabel baru: inventory_item
		is_inventory_opened = not is_inventory_opened
		inventory_item.visible = not inventory_item.visible
		
		# Atur Mouse
		if inventory_item.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("use_item"): # Buat action 'use_item'
		use_selected_item()
	
	SetState()
	UpdateWeapon()
	UpdateAnimation()
	_process_stamina(delta)
	
func select_consumable(item_data):
	selected_item = item_data
	if item_slot_icon:
		# Sprite2D juga punya properti 'texture', jadi ini tetap jalan
		item_slot_icon.texture = item_data["icon"]

func use_selected_item():
	if selected_item != null:
		print("Menggunakan: ", selected_item["name"])
		
		# Logika efek item
		if selected_item["name"] == "Health Potion":
			health += selected_item["value"]
			# Batasi max health (sesuai logika kamu, misal 12)
			if health > 12: health = 12
			update_hearts()
			
		elif selected_item["name"] == "Stamina Potion":
			current_stamina += selected_item["value"]
			# Batasi max stamina
			if current_stamina > max_stamina: current_stamina = max_stamina
			update_stamina_ui()
			
		if inventory_item.has_method("remove_item"):
			inventory_item.remove_item(selected_item)
		
		# Kosongkan variabel di tangan Player
		selected_item = null
		
		# Kosongkan gambar di HUD (Item Slot)
		if item_slot_icon:
			item_slot_icon.texture = null
		# KOSONGKAN SLOT SETELAH DIPAKAI (Opsional)
		# Jika item habis pakai, reset selected_item jadi null
		# Dan hapus dari inventory (butuh logika hapus di script inventory)
		

func _process_stamina(delta: float) -> void:
	# Hanya regen jika stamina belum penuh
	if current_stamina < max_stamina:
		
		# Opsional: Jangan regen saat sedang lari/dash (biar lebih fair)
		if not is_dashing and not is_attacking:
			# Tambahkan stamina sedikit demi sedikit setiap frame
			current_stamina += regen_rate * delta
			
			# Pastikan tidak melebihi batas maksimal
			if current_stamina > max_stamina:
				current_stamina = max_stamina
			
			# Update UI setiap frame agar terlihat smooth
			update_stamina_ui()

func check_weapon_unlocks():
	# 1. Cek Rencong (Slot 2)
	if Global.unlocked_weapons["rencong"] == true:
		# Jika sudah terbuka: Sembunyikan gembok
		rencong.visible = true
		locked_rencong.visible = false
	else:
		# Jika terkunci: Munculkan gembok
		rencong.visible = false
		locked_rencong.visible = true
		# Pastikan sprite asli rencong sembunyi (jika ada logic visual statis)
		rencong_idle.visible = false 

	# 2. Cek Keris (Slot 3)
	if Global.unlocked_weapons["keris"] == true:
		keris.visible = true
		locked_keris.visible = false
	else:
		keris.visible = false
		locked_keris.visible = true
		keris_idle.visible = false

func update_stamina_ui() -> void:
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = current_stamina

func _physics_process(delta: float) -> void:
	is_attacking = false
	is_hurt = false
	if is_on_floor(): coyote_timer = coyote_time
	else: coyote_timer = max(coyote_timer - delta, 0.0)
	if is_hurt:
		# --- LOGIKA SAAT TERPENTAL ---
		# Player tidak bisa dikontrol, hanya meluncur akibat dorongan
		# Tambahkan sedikit gesekan (friction) di udara agar tidak melayang selamanya
		velocity.x = move_toward(velocity.x, 0, 500 * delta)
	else:
		if jump_buffer_timer > 0.0 and (is_on_floor() or coyote_timer > 0.0) and not is_attacking:
			jump_buffer_timer = 0.0; is_jumping = true; velocity.y = jump_force
			state = weapon + "_jumping"; UpdateAnimation()
		if jump_buffer_timer > 0.0: jump_buffer_timer -= delta
		if not is_on_floor():
			if is_dashing: velocity.y = 0.0
			else:
				var g := gravity
				if velocity.y < 0.0:
					if Input.is_action_just_released("jump"): g *= jump_cut_multiplier
					elif absf(velocity.y) <= apex_threshold: g *= apex_gravity_multiplier
				else: g *= fall_gravity_multiplier
				velocity.y = min(velocity.y + g * delta, 3000)
		else:
			if is_jumping:
				is_jumping = false
				if not is_attacking and not is_hurt:
					state = weapon + ("_idle" if direction == Vector2.ZERO else "_run")
					is_dashing = false; can_air_dash = true; UpdateAnimation()
		if is_dashing:
			dash_timer -= delta
			if dash_timer <= 0.0: is_dashing = false
			velocity.x = float(dash_dir_x) * dash_speed
		elif is_attacking:
			if is_on_floor(): velocity.x = 0.0
			else:
				var target := direction.x * move_speed
				velocity.x = move_toward(velocity.x, target, 900.0 * delta)
		else:
			var target := direction.x * move_speed
			var accel := 1800.0 if is_on_floor() else 900.0
			velocity.x = move_toward(velocity.x, target, accel * delta)
	move_and_slide()
	_check_player_collision()

func show_notification(text_content: String, duration: float = 3.0) -> void:
	# 1. Ubah Teks
	if label:
		label.text = text_content
	
	# 2. Reset kondisi visual
	tutorial_bubble.visible = true
	tutorial_bubble.modulate.a = 0.0 # Mulai dari transparan
	
	# 3. Reset Tween jika sedang berjalan (biar animasi tidak tabrakan)
	if notification_tween:
		notification_tween.kill()
	
	# 4. Buat Animasi Baru
	notification_tween = create_tween()
	
	# Fade In (0.5 detik)
	notification_tween.tween_property(tutorial_bubble, "modulate:a", 1.0, 0.5)
	
	# Diam/Baca (sesuai durasi)
	notification_tween.tween_interval(duration)
	
	# Fade Out (0.5 detik)
	notification_tween.tween_property(tutorial_bubble, "modulate:a", 0.0, 0.5)
	
	# Sembunyikan setelah selesai
	notification_tween.tween_callback(tutorial_bubble.hide)

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		if body != self:
			# Logic damage ke musuh (Kronco damage 1, Skeleton damage 2, dst)
			if body is Demon: body.take_damage(1, self)
			elif body is SkeletonLvl1: body.take_damage(1, self)
			else: body.take_damage(1)

func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is Kronco:
			take_damage(1)

func take_damage(amount: int, source: Node2D = null) -> void:
	if is_invincible: return
	
	health -= amount
	print("Player Hit! Sisa Health: ", health)
	update_hearts()
	
	if health <= 0:
		die()
	else:
		# Panggil fungsi Knockback
		apply_knockback(source)
		start_invincibility()

func apply_knockback(source: Node2D):
	if source:
		is_hurt = true
		
		# Hitung arah: Dari Musuh MENUJU Player
		# (Posisi Player - Posisi Musuh)
		var knockback_dir = (global_position - source.global_position).normalized()
		
		# Dorong ke X dan sedikit ke atas (Y) biar ada efek loncat dikit
		velocity.x = knockback_dir.x * knockback_force
		
		# Tunggu sebentar (misal 0.3 detik) sebelum bisa gerak lagi
		await get_tree().create_timer(0.3).timeout
		is_hurt = false

func start_invincibility() -> void:
	is_invincible = true
	modulate.a = 0.5
	await get_tree().create_timer(invincibility_duration).timeout
	modulate.a = 1.0
	is_invincible = false

func die() -> void:
	print("Player Mati")
	get_tree().reload_current_scene()

func _start_air_dash() -> void:
	if current_stamina >= 3.0:
		# Kurangi Stamina
		current_stamina -= 3.0
		update_stamina_ui()
		
		# Jalankan Dash
		is_dashing = true
		can_air_dash = false
		dash_timer = dash_duration
		dash_dir_x = -1 if cardinal_direction == Vector2.LEFT else 1
		velocity.y = 0.0
		UpdateAnimation()
	else:
		print("Stamina tidak cukup untuk Dash!")
		# Opsional: Tambahkan efek suara gagal atau visual merah di bar

func SetState() -> bool:
	var new_state : String = state
	if is_dashing: return false
	if is_on_floor() and not is_attacking:
		if Input.is_action_just_pressed("jump"):
			new_state = weapon + "_jumping"; is_jumping = true; velocity.y = jump_force
		elif direction == Vector2.ZERO: move_speed = 150; new_state = weapon + "_idle"
		elif Input.is_action_pressed("run"): move_speed = 300; new_state = weapon + "_run"
		else: move_speed = 300; new_state = weapon + "_run"
	if Input.is_action_just_pressed("basic_hit") and not is_attacking and not is_inventory_opened:
		if current_stamina >= 1.0:
			# Kurangi Staminais_inventory_opened
			current_stamina -= 1.0
			update_stamina_ui()
			
			# Jalankan Attack
			new_state = weapon + "_attack"
			is_attacking = true
			attack_area.monitoring = true 
		else:
			print("Stamina habis!")
			return false # Batalkan attack
	if new_state == state: return false
	state = new_state; return true

func UpdateWeapon():
	var old_weapon = weapon
	if Input.is_action_just_pressed("slot_1"): weapon = "pedang" 
	elif Input.is_action_just_pressed("slot_2"):
		if Global.unlocked_weapons["rencong"] == true:
			weapon = "rencong"
		else:
			print("Senjata Rencong Belum Terbuka!")
			# Optional: Play sound error / Shake UI
	elif Input.is_action_just_pressed("slot_3"): 
		if Global.unlocked_weapons["keris"] == true:
			weapon = "keris"
		else:
			print("Senjata Keris Belum Terbuka!")
	if old_weapon != weapon and not is_attacking:
		if "idle" in state: state = weapon + "_idle"
		elif "run" in state: state = weapon + "_run"
		elif "jumping" in state: state = weapon + "_jumping"
		UpdateAnimation()

func UpdateAnimation() -> void:
	keris_attack.hide(); keris_idle.hide(); keris_run.hide()
	rencong_attack.hide(); rencong_run.hide(); rencong_idle.hide()
	pedang_attack.hide(); pedang_idle.hide(); pedang_run.hide()
	var flip_scale = -1 if cardinal_direction == Vector2.LEFT else 1
	attack_area.scale.x = flip_scale 
	if state == "pedang_idle":   pedang_idle.show(); pedang_idle.scale.x = flip_scale
	elif state == "pedang_run":  pedang_run.show(); pedang_run.scale.x = flip_scale
	elif state == "pedang_attack": pedang_attack.show(); pedang_attack.scale.x = flip_scale
	elif state == "pedang_jumping": pedang_idle.show(); pedang_idle.scale.x = flip_scale
	elif state == "keris_idle":  keris_idle.show(); keris_idle.scale.x = flip_scale
	elif state == "keris_run":   keris_run.show(); keris_run.scale.x = flip_scale
	elif state == "keris_attack": keris_attack.show(); keris_attack.scale.x = flip_scale
	elif state == "rencong_idle": rencong_idle.show(); rencong_idle.scale.x = flip_scale
	elif state == "rencong_run":  rencong_run.show(); rencong_run.scale.x = flip_scale
	elif state == "rencong_attack": rencong_attack.show(); rencong_attack.scale.x = flip_scale
	if animation_player.current_animation != state:
		if animation_player.has_animation(state):
			animation_player.play(state)

func _on_animation_player_animation_finished(anim_name: String) -> void:
	if "attack" in anim_name:
		is_attacking = false; attack_area.monitoring = false; state = weapon + "_idle"; UpdateAnimation()

# --- LOGIKA UPDATE HEARTS (PERBAIKAN) ---
func update_hearts():
	for i in range(heart_list.size()):
		# Karena isi list adalah AnimatedSprite2D, kita ambil langsung
		var heart_anim = heart_list[i]
		
		# Hitung sisa nyawa untuk jantung ke-i
		var heart_health = clamp(health - (i * max_hp_per_heart), 0, max_hp_per_heart)
		
		# Konversi ke Frame (Frame 0=Penuh, Frame 5=Kosong)
		# Jika heart_health = 5 (Penuh), Frame = 5-5 = 0.
		# Jika heart_health = 0 (Kosong), Frame = 5-0 = 5.
		var target_frame = max_hp_per_heart - heart_health
		
		heart_anim.frame = target_frame
