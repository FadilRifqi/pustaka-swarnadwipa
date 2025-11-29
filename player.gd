class_name Player extends CharacterBody2D

# --- VARIABLES ---
var heart_list : Array[AnimatedSprite2D] 
var money: int = 0 # Uang (Gold)
# Health Logic
var health : float = 12.0
var max_hp_per_heart : float = 4.0 
var is_inventory_opened = false
@export var skill_sprite_offset: Vector2 = Vector2(70, 0)
# Stamina
var max_stamina : float = 10.0
var current_stamina : float = 10.0
var stamina_timer : float = 0.0
@onready var stamina_bar: ProgressBar = $HealthLayer/Stamina
var regen_rate : float = 1.0 / 1.8
@onready var skill_area: Area2D = $SkillArea

# Movement
var cardinal_direction : Vector2 = Vector2.RIGHT
var direction : Vector2 = Vector2.ZERO
@export var move_speed : float = 300.0

# Skill & Dash Settings
@export var dash_speed: float = 600.0
@export var skill_dash_distance: float = 200.0 # JARAK GESER SKILL (200px)

# Nodes
@onready var attack_area: Area2D = $AttackArea
@onready var tutorial_bubble: PanelContainer = $TutorialBubble
@onready var label: Label = $TutorialBubble/Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

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
var is_attacking : bool = false
var is_using_skill : bool = false # Status Skill

# Damage & Invincibility
var is_invincible : bool = false
var invincibility_duration : float = 1.0 
@onready var gold: Sprite2D = $HealthLayer/Gold
@onready var gold_label: Label = $HealthLayer/Label

# Physics
var gravity : float = 980.0
var jump_force : float = -500.0
var is_jumping : bool = false
var coyote_time: float = 0.12
var jump_buffer_time: float = 0.12
var fall_gravity_multiplier: float = 2.0
var jump_cut_multiplier: float = 2.7
var apex_gravity_multiplier: float = 0.85
var apex_threshold: float = 120.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var damage_sword_basic: int = 1
var damage_rencong_basic: int = 2
var damage_rencong_skill: int = 3
var damage_keris_basic: int = 3
var damage_keris_skill: int = 4
# Dash Logic
var is_dashing: bool = false
var can_air_dash: bool = true
var dash_dir_x: int = 1
var dash_duration: float = 0.08
var dash_timer: float = 0.0
var is_hurt: bool = false

@export var knockback_force: float = 250.0 
@export var character_scale: float = 3.0 

# --- ANIMASI BARU ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	var hearts_parent = $HealthLayer/HBoxContainer
	scale = Vector2(character_scale, character_scale)
	check_weapon_unlocks()
	gold.visible = false
	gold_label.visible = false
	update_money_ui()
	
	if hearts_parent:
		for child in hearts_parent.get_children():
			if child is AnimatedSprite2D:
				child.scale.x = -child.scale.x
				heart_list.append(child)
			
	# Setup Hitbox
	attack_area.monitoring = false
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)
	
	skill_area.monitoring = false
	if not skill_area.body_entered.is_connected(_on_skill_area_body_entered):
		skill_area.body_entered.connect(_on_skill_area_body_entered)
	
	# Setup Animation Signal
	if not animated_sprite.animation_finished.is_connected(_on_animated_sprite_animation_finished):
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)
	
	UpdateAnimation()
	update_hearts()
	update_stamina_ui()

func _on_skill_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		if body != self:
			# 1. Tentukan Damage Skill Berdasarkan Senjata
			var final_damage = 0
			
			if weapon == "rencong":
				final_damage = damage_rencong_skill
			elif weapon == "keris":
				final_damage = damage_keris_skill
			else:
				# Sword tidak punya skill damage area
				return 
			
			print("Skill Hit! Weapon: ", weapon, " | Damage: ", final_damage)

			# 2. Kirim Damage
			if body is Demon: body.take_damage(final_damage, self)
			elif body is SkeletonLvl1: body.take_damage(final_damage, self)
			elif body is Kronco: body.take_damage(final_damage, self)
			elif body is Cindaku: body.take_damage(final_damage, self)
			elif body is BeguGanjang: body.take_damage(final_damage, self)
			else: body.take_damage(final_damage)

func _process(delta: float) -> void:
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	if not is_attacking and not is_using_skill:
		if direction.x != 0:
			cardinal_direction = Vector2.RIGHT if direction.x > 0 else Vector2.LEFT
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor(): 
			jump_buffer_timer = jump_buffer_time
	
	if Input.is_action_just_pressed("dash"):
		if not is_attacking and not is_using_skill and not is_dashing:
			start_dash()
	
	if Input.is_action_just_pressed("inventory"):
		is_inventory_opened = not is_inventory_opened
		inventory_item.visible = not inventory_item.visible
		gold.visible = not gold.visible
		gold_label.visible = not gold_label.visible
		if inventory_item.visible: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if Input.is_action_just_pressed("use_item"):
		use_selected_item()
	
	SetState()
	UpdateWeapon()
	UpdateAnimation()
	_process_stamina(delta)

func start_dash() -> void:
	# 1. Cek Stamina
	if current_stamina >= 3.0:
		current_stamina -= 3.0
		update_stamina_ui()
		
		# 2. Set Status Dash
		is_dashing = true
		can_air_dash = false # Opsional: Matikan air dash agar tidak spam di udara
		dash_timer = dash_duration
		
		# 3. Tentukan Arah Dash (Sesuai input atau hadap)
		if direction.x != 0:
			dash_dir_x = direction.x 
		else:
			dash_dir_x = -1 if cardinal_direction == Vector2.LEFT else 1
			
		# 4. Reset Velocity Y (Agar tidak jatuh saat dash di udara)
		velocity.y = 0.0
		
		UpdateAnimation()
	else:
		show_notification("Need Stamina!", 1.0)
		print("Stamina tidak cukup untuk Dash!")

# --- PHYSICS PROCESS ---
func _physics_process(delta: float) -> void:
	if is_on_floor(): coyote_timer = coyote_time
	else: coyote_timer = max(coyote_timer - delta, 0.0)
	
	if is_hurt:
		velocity.x = move_toward(velocity.x, 0, 500 * delta)
	
	elif is_using_skill:
		# Matikan Physics saat skill agar tidak jatuh atau bergesekan
		velocity = Vector2.ZERO
		
	else:
		# Jump Logic
		if jump_buffer_timer > 0.0 and (is_on_floor() or coyote_timer > 0.0) and not is_attacking:
			jump_buffer_timer = 0.0; is_jumping = true; velocity.y = jump_force
			state = weapon + "_jumping"; UpdateAnimation()
		if jump_buffer_timer > 0.0: jump_buffer_timer -= delta
		
		# Gravity
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
				if not is_attacking and not is_hurt and not is_using_skill:
					state = weapon + ("_idle" if direction == Vector2.ZERO else "_run")
					is_dashing = false; can_air_dash = true; UpdateAnimation()
		
		# Movement Horizontal
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

# --- STATE MANAGEMENT & INPUT ---
func SetState() -> bool:
	var new_state : String = state
	# Jangan ganti state kalau sedang dash atau skill
	if is_dashing or is_using_skill: return false 
	
	if is_on_floor() and not is_attacking:
		if Input.is_action_just_pressed("jump"):
			new_state = weapon + "_jumping"; is_jumping = true; velocity.y = jump_force
		elif direction == Vector2.ZERO: move_speed = 150; new_state = weapon + "_idle"
		elif Input.is_action_pressed("run"): move_speed = 300; new_state = weapon + "_run"
		else: move_speed = 300; new_state = weapon + "_run"
	
	# BASIC ATTACK
	if Input.is_action_just_pressed("basic_hit") and not is_attacking and not is_inventory_opened:
		if current_stamina >= 1.0:
			current_stamina -= 1.0
			update_stamina_ui()
			new_state = weapon + "_attack"
			is_attacking = true
			attack_area.monitoring = true 
		else:
			show_notification("Need Stamina!", 1.0)
			return false
	
	# SKILL INPUT
	if Input.is_action_just_pressed("skill") and not is_attacking and not is_inventory_opened:
		if weapon == "sword":
			show_notification("Sword has no skill!", 1.0)
			return false
			
		if current_stamina >= 3.0:
			current_stamina -= 3.0
			update_stamina_ui()
			
			# Set State Skill
			new_state = weapon + "_skill"
			is_using_skill = true
			skill_area.monitoring = true 
			
			# Jalankan Geser 200px
			perform_skill_dash()
			
		else:
			show_notification("Need Stamina!", 1.0)
			return false

	if new_state == state: return false
	state = new_state; return true

# --- LOGIKA TELEPORT SKILL ---
func perform_skill_dash() -> void:
	var is_left = cardinal_direction == Vector2.LEFT
	
	if is_left:
		animated_sprite.offset.x = -skill_sprite_offset.x
	else:
		animated_sprite.offset.x = skill_sprite_offset.x
		
	animated_sprite.offset.y = skill_sprite_offset.y
	
	# Player akan tetap dalam state "skill" (is_using_skill = true)
	# sampai animasi skill selesai dimainkan di fungsi _on_animated_sprite_animation_finished

func UpdateWeapon():
	var old_weapon = weapon
	if Input.is_action_just_pressed("slot_1"): weapon = "sword" 
	elif Input.is_action_just_pressed("slot_2"):
		if Global.unlocked_weapons["rencong"] == true: weapon = "rencong"
		else: show_notification("Locked!", 0.5)
	elif Input.is_action_just_pressed("slot_3"): 
		if Global.unlocked_weapons["keris"] == true: weapon = "keris"
		else: show_notification("Locked!", 0.5)
	
	if old_weapon != weapon and not is_attacking and not is_using_skill:
		if "idle" in state: state = weapon + "_idle"
		elif "run" in state: state = weapon + "_run"
		elif "jumping" in state: state = weapon + "_jumping"
		UpdateAnimation()

func UpdateAnimation() -> void:
	var is_left = cardinal_direction == Vector2.LEFT
	animated_sprite.flip_h = is_left
	
	if is_left: attack_area.scale.x = -1
	else: attack_area.scale.x = 1
	
	if is_left: skill_area.scale.x = -1
	else: skill_area.scale.x = 1
	
	if animated_sprite.animation != state:
		if animated_sprite.sprite_frames.has_animation(state):
			animated_sprite.play(state)
		else:
			print("Warning: Animasi tidak ditemukan -> ", state)
			animated_sprite.play(weapon + "_idle")
	

# --- SINYAL ANIMASI SELESAI ---
func _on_animated_sprite_animation_finished() -> void:
	var anim_name = animated_sprite.animation
	var dir = -1 if cardinal_direction == Vector2.LEFT else 1
	
	# Handle Selesai Attack atau Skill
	if "attack" in anim_name :
		is_attacking = false
		is_using_skill = false # Kembalikan kontrol gerak ke player
		attack_area.monitoring = false
		state = weapon + "_idle"
		UpdateAnimation()
	if "skill" in anim_name:	
		is_using_skill = false # Kembalikan kontrol gerak ke player
		skill_area.monitoring = false
		state = weapon + "_idle"
		UpdateAnimation()
		animated_sprite.offset = Vector2.ZERO

# --- HELPER FUNCTIONS ---
func select_consumable(item_data, index):
	selected_item = item_data
	selected_item_index = index 
	if item_slot_icon: item_slot_icon.texture = item_data["icon"]

func use_selected_item():
	if selected_item != null:
		if selected_item["name"] == "Health Potion":
			health += selected_item["value"]
			if health > 12.0: health = 12.0
			update_hearts()
		elif selected_item["name"] == "Stamina Potion":
			current_stamina += selected_item["value"]
			if current_stamina > max_stamina: current_stamina = max_stamina
			update_stamina_ui()
			
		if inventory_item.has_method("remove_item_at_index"):
			inventory_item.remove_item_at_index(selected_item_index)
		
		selected_item = null
		selected_item_index = -1
		if item_slot_icon: item_slot_icon.texture = null

func _process_stamina(delta: float) -> void:
	if current_stamina < max_stamina:
		if not is_dashing and not is_attacking and not is_using_skill:
			current_stamina += regen_rate * delta
			if current_stamina > max_stamina: current_stamina = max_stamina
			update_stamina_ui()

func update_stamina_ui() -> void:
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = current_stamina

func check_weapon_unlocks():
	rencong_ui.visible = Global.unlocked_weapons["rencong"]
	locked_rencong.visible = not Global.unlocked_weapons["rencong"]
	keris_ui.visible = Global.unlocked_weapons["keris"]
	locked_keris.visible = not Global.unlocked_weapons["keris"]

func show_notification(text_content: String, duration: float = 3.0) -> void:
	# Kita ubah teks tunggal menjadi Array[String] karena DialogManager butuh Array
	var lines: Array[String] = [text_content]
	var dialog_pos = global_position + Vector2(0, -100)
	DialogManager.start_dialog(dialog_pos, lines, duration)

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		if body != self:
			# 1. Tentukan Damage Berdasarkan Senjata
			var final_damage = 1 # Default (Sword)
			
			if weapon == "sword":
				final_damage = damage_sword_basic
			elif weapon == "rencong":
				final_damage = damage_rencong_basic
			elif weapon == "keris":
				final_damage = damage_keris_basic
			
			print("Basic Attack! Weapon: ", weapon, " | Damage: ", final_damage)

			# 2. Kirim Damage ke Musuh
			# (Menggunakan 'self' agar musuh tahu arah knockback dari player)
			if body is Demon: body.take_damage(final_damage, self)
			elif body is SkeletonLvl1: body.take_damage(final_damage, self)
			elif body is Kronco: body.take_damage(final_damage, self)
			elif body is Cindaku: body.take_damage(final_damage, self)
			elif body is BeguGanjang: body.take_damage(final_damage, self)
			else: body.take_damage(final_damage) # Default untuk musuh lain

func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is Kronco: take_damage(1)

func take_damage(amount: float, source: Node2D = null) -> void:
	print("is invisible", is_invincible)
	if is_invincible: return
	health -= amount
	print(health)
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
		if velocity.y < 0: velocity.y = 0
		await get_tree().create_timer(0.3).timeout
		is_hurt = false

func start_invincibility() -> void:
	is_invincible = true; modulate.a = 0.5
	await get_tree().create_timer(invincibility_duration).timeout
	modulate.a = 1.0; is_invincible = false

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

func update_hearts():
	for i in range(heart_list.size()):
		var heart_anim = heart_list[i]
		var heart_health = clamp(health - (i * max_hp_per_heart), 0, max_hp_per_heart)
		heart_anim.frame = (max_hp_per_heart - heart_health) 
		
func update_money_ui() -> void:
	if gold_label:
		gold_label.text = str(money)

func add_money(amount: int) -> void:
	money += amount
	print("Money Added: ", amount, " | Total: ", money)
	update_money_ui()
