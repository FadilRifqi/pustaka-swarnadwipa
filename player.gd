class_name Player extends CharacterBody2D

# --- VARIABLES ---
var heart_list : Array[AnimatedSprite2D] 

# Health Logic
var health : int = 12 
var max_hp_per_heart : int = 4 
var is_inventory_opened = false

# Stamina
var max_stamina : float = 10.0
var current_stamina : float = 10.0
var stamina_timer : float = 0.0
@onready var stamina_bar: ProgressBar = $HealthLayer/Stamina
var regen_rate : float = 1.0 / 1.8

var cardinal_direction : Vector2 = Vector2.RIGHT
var direction : Vector2 = Vector2.ZERO
@export var move_speed : float = 300.0

# Nodes
@onready var attack_area: Area2D = $AttackArea
@onready var tutorial_bubble: PanelContainer = $TutorialBubble
@onready var label: Label = $TutorialBubble/Label

# UI Nodes
@onready var keris_ui: Sprite2D = $HealthLayer/Keris
@onready var rencong_ui: Sprite2D = $HealthLayer/Rencong
@onready var locked_rencong: Sprite2D = $HealthLayer/LockedRencong
@onready var locked_keris: Sprite2D = $HealthLayer/LockedKeris
@onready var inventory_item: TextureRect = $HealthLayer/InventoryItem 
@onready var item_slot_icon: Sprite2D = $HealthLayer/HealthPotion

var selected_item = null
var selected_item_index: int = -1
var notification_tween: Tween

# State & Weapon
var state : String = "sword_idle"
var weapon : String = "sword"
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

@export var knockback_force: float = 250.0 
@export var dash_speed: float = 900.0
@export var character_scale: float = 3.0 

# --- ANIMASI BARU ---
# Pastikan node AnimatedSprite2D sudah ada di Scene Player
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	var hearts_parent = $HealthLayer/HBoxContainer
	scale = Vector2(character_scale, character_scale)
	check_weapon_unlocks()
	
	if hearts_parent:
		for child in hearts_parent.get_children():
			if child is AnimatedSprite2D:
				child.scale.x = -child.scale.x
				heart_list.append(child)
			
	# Setup Hitbox
	attack_area.monitoring = false
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)
	
	# Setup Signal Animasi Selesai (Khusus AnimatedSprite2D)
	if not animated_sprite.animation_finished.is_connected(_on_animated_sprite_animation_finished):
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)
	
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
		is_inventory_opened = not is_inventory_opened
		inventory_item.visible = not inventory_item.visible
		if inventory_item.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if Input.is_action_just_pressed("use_item"):
		use_selected_item()
	
	SetState()
	UpdateWeapon()
	UpdateAnimation()
	_process_stamina(delta)

func select_consumable(item_data, index):
	selected_item = item_data
	selected_item_index = index # Simpan nomor slotnya
	
	if item_slot_icon:
		item_slot_icon.texture = item_data["icon"]

func use_selected_item():
	if selected_item != null:
		print("Menggunakan: ", selected_item["name"])
		
		# 1. Logika Efek Item (Tetap Sama)
		if selected_item["name"] == "Health Potion":
			health += selected_item["value"]
			if health > 12: health = 12
			update_hearts()
		elif selected_item["name"] == "Stamina Potion":
			current_stamina += selected_item["value"]
			if current_stamina > max_stamina: current_stamina = max_stamina
			update_stamina_ui()
			
		# 2. Hapus Item Berdasarkan INDEX
		if inventory_item.has_method("remove_item_at_index"):
			# Hapus item di slot yang spesifik
			inventory_item.remove_item_at_index(selected_item_index)
		
		# 3. Reset
		selected_item = null
		selected_item_index = -1
		
		if item_slot_icon:
			item_slot_icon.texture = null

func _process_stamina(delta: float) -> void:
	if current_stamina < max_stamina:
		if not is_dashing and not is_attacking:
			current_stamina += regen_rate * delta
			if current_stamina > max_stamina:
				current_stamina = max_stamina
			update_stamina_ui()

func check_weapon_unlocks():
	if Global.unlocked_weapons["rencong"] == true:
		rencong_ui.visible = true
		locked_rencong.visible = false
	else:
		rencong_ui.visible = false
		locked_rencong.visible = true

	if Global.unlocked_weapons["keris"] == true:
		keris_ui.visible = true
		locked_keris.visible = false
	else:
		keris_ui.visible = false
		locked_keris.visible = true

func update_stamina_ui() -> void:
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = current_stamina

func _physics_process(delta: float) -> void:
	if is_on_floor(): coyote_timer = coyote_time
	else: coyote_timer = max(coyote_timer - delta, 0.0)
	
	if is_hurt:
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
	if label: label.text = text_content
	tutorial_bubble.visible = true; tutorial_bubble.modulate.a = 0.0
	if notification_tween: notification_tween.kill()
	notification_tween = create_tween()
	notification_tween.tween_property(tutorial_bubble, "modulate:a", 1.0, 0.5)
	notification_tween.tween_interval(duration)
	notification_tween.tween_property(tutorial_bubble, "modulate:a", 0.0, 0.5)
	notification_tween.tween_callback(tutorial_bubble.hide)

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		if body != self:
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
	if health <= 0: die()
	else:
		apply_knockback(source)
		start_invincibility()

func apply_knockback(source: Node2D):
	if source:
		is_hurt = true
		var knockback_dir = (global_position - source.global_position).normalized()
		velocity.x = knockback_dir.x * knockback_force
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
		current_stamina -= 3.0
		update_stamina_ui()
		is_dashing = true; can_air_dash = false; dash_timer = dash_duration
		dash_dir_x = -1 if cardinal_direction == Vector2.LEFT else 1
		velocity.y = 0.0
		UpdateAnimation()
	else:
		print("Stamina tidak cukup untuk Dash!")

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
			current_stamina -= 1.0
			update_stamina_ui()
			new_state = weapon + "_attack"
			is_attacking = true
			attack_area.monitoring = true 
		else:
			print("Stamina habis!")
			return false
			
	if new_state == state: return false
	state = new_state; return true

func UpdateWeapon():
	var old_weapon = weapon
	if Input.is_action_just_pressed("slot_1"): weapon = "sword" 
	elif Input.is_action_just_pressed("slot_2"):
		if Global.unlocked_weapons["rencong"] == true: weapon = "rencong"
		else: print("Senjata Rencong Belum Terbuka!")
	elif Input.is_action_just_pressed("slot_3"): 
		if Global.unlocked_weapons["keris"] == true: weapon = "keris"
		else: print("Senjata Keris Belum Terbuka!")
	
	if old_weapon != weapon and not is_attacking:
		if "idle" in state: state = weapon + "_idle"
		elif "run" in state: state = weapon + "_run"
		elif "jumping" in state: state = weapon + "_jumping"
		UpdateAnimation()

# --- UPDATE ANIMATION (VERSI ANIMATED SPRITE) ---
func UpdateAnimation() -> void:
	# Flip Logic untuk AnimatedSprite
	var is_left = cardinal_direction == Vector2.LEFT
	animated_sprite.flip_h = is_left
	
	# Flip Hitbox (Manual Scale)
	if is_left: attack_area.scale.x = -1
	else: attack_area.scale.x = 1
	
	# Mainkan animasi berdasarkan state
	# Pastikan nama animasi di SpriteFrames SAMA PERSIS dengan string 'state'
	# Contoh: "sword_idle", "sword_run", "keris_attack"
	if animated_sprite.animation != state:
		animated_sprite.play(state)

# --- SINYAL ANIMASI SELESAI ---
func _on_animated_sprite_animation_finished() -> void:
	# Jika nama animasi mengandung kata "attack"
	if "attack" in animated_sprite.animation:
		is_attacking = false
		attack_area.monitoring = false
		state = weapon + "_idle"
		UpdateAnimation()

func update_hearts():
	for i in range(heart_list.size()):
		var heart_anim = heart_list[i]
		var heart_health = clamp(health - (i * max_hp_per_heart), 0, max_hp_per_heart) 
		var target_frame = max_hp_per_heart - heart_health
		heart_anim.frame = target_frame
