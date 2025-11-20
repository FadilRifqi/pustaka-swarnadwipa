class_name Player extends CharacterBody2D

# --- VARIABLES ---
var heart_list : Array[TextureRect]
var health : int = 3
var cardinal_direction : Vector2 = Vector2.RIGHT
var direction : Vector2 = Vector2.ZERO
@export var move_speed : float = 150.0
@onready var attack_area: Area2D = $AttackArea

# PENTING: Pastikan node "Attack_Range" di Scene adalah "Area2D", bukan CollisionShape2D saja!

# State & Weapon
var state : String = "pedang_idle"
var weapon : String = "pedang"
var last_pressed : String = ""
var next_attack : String = ""
var is_attacking : bool = false

# Damage & Invincibility Variables
var is_invincible : bool = false
var invincibility_duration : float = 1.0 

# Physics Variables
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

# Air dash Variables
var is_dashing: bool = false
var can_air_dash: bool = true
var dash_dir_x: int = 1
var dash_duration: float = 0.18
var dash_timer: float = 0.0
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
	
	if hearts_parent:
		for child in hearts_parent.get_children():
			heart_list.append(child)
			
	# --- SETUP HITBOX ---
	# Matikan hitbox saat mulai game
	attack_area.monitoring = false
	
	# Hubungkan sinyal body_entered lewat kode
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)
	
	UpdateAnimation()
	update_hearts()

func _process(delta: float) -> void:
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	if direction.x != 0:
		cardinal_direction = Vector2.RIGHT if direction.x > 0 else Vector2.LEFT

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			jump_buffer_timer = jump_buffer_time
		elif not is_attacking and not is_dashing and can_air_dash:
			_start_air_dash()

	SetState()
	UpdateWeapon()
	UpdateAnimation()

func _physics_process(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	if jump_buffer_timer > 0.0 and (is_on_floor() or coyote_timer > 0.0) and not is_attacking:
		jump_buffer_timer = 0.0
		is_jumping = true
		velocity.y = jump_force
		state = weapon + "_jumping"
		UpdateAnimation()

	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	if not is_on_floor():
		if is_dashing:
			velocity.y = 0.0
		else:
			var g := gravity
			if velocity.y < 0.0:
				if Input.is_action_just_released("jump"): g *= jump_cut_multiplier
				elif absf(velocity.y) <= apex_threshold: g *= apex_gravity_multiplier
			else:
				g *= fall_gravity_multiplier
			velocity.y = min(velocity.y + g * delta, 3000)
	else:
		if is_jumping:
			is_jumping = false
			if not is_attacking:
				state = weapon + ("_idle" if direction == Vector2.ZERO else "_run")
				is_dashing = false
				can_air_dash = true
				UpdateAnimation()

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
	_check_player_collision() # Cek kalau player ditabrak musuh

# --- LOGIKA SERANGAN (PLAYER HITBOX) ---
# Fungsi ini otomatis dipanggil saat Attack_Range (Area2D) mendeteksi body masuk
# TETAPI hanya aktif saat attack_area.monitoring = true (yang kita set di SetState)
func _on_attack_area_body_entered(body: Node2D) -> void:
	# JANGAN pakai "if body is Kronco", karena itu cuma deteksi Kronco.
	
	# GUNAKAN "has_method" agar bisa memukul SEMUA musuh (Kronco, Skeleton, dll)
	if body.has_method("take_damage"):
		# Pastikan tidak memukul diri sendiri
		if body != self:
			body.take_damage(1)

# --- LOGIKA PLAYER DITABRAK MUSUH ---
func _check_player_collision() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is Kronco:
			take_damage(1) # Kurangi darah player

func take_damage(amount: int) -> void:
	if is_invincible: return
	health -= amount
	print("Player Hit! Sisa Health: ", health)
	update_hearts()
	if health <= 0: die()
	else: start_invincibility()

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
	is_dashing = true
	can_air_dash = false
	dash_timer = dash_duration
	dash_dir_x = -1 if cardinal_direction == Vector2.LEFT else 1
	velocity.y = 0.0
	UpdateAnimation()

func SetState() -> bool:
	var new_state : String = state
	if is_dashing: return false
	
	if is_on_floor() and not is_attacking:
		if Input.is_action_just_pressed("jump"):
			new_state = weapon + "_jumping"
			is_jumping = true
			velocity.y = jump_force
		elif direction == Vector2.ZERO:
			move_speed = 150
			new_state = weapon + "_idle"
		elif Input.is_action_pressed("run"):
			move_speed = 250
			new_state = weapon + "_run"
		else:
			move_speed = 150
			new_state = weapon + "_run"
	
	# --- ATTACK LOGIC ---
	if Input.is_action_just_pressed("basic_hit") and not is_attacking:
		new_state = weapon + "_attack"
		is_attacking = true
		
		# NYALAKAN HITBOX! 
		# Ini membuat Area2D mulai mendeteksi musuh.
		# Godot akan otomatis memanggil _on_attack_area_body_entered jika ada musuh.
		attack_area.monitoring = true 
	
	if new_state == state: return false
	state = new_state
	return true

func UpdateWeapon():
	var old_weapon = weapon
	if Input.is_action_just_pressed("slot_1"): weapon = "pedang" 
	elif Input.is_action_just_pressed("slot_2"): weapon = "rencong" 
	elif Input.is_action_just_pressed("slot_3"): weapon = "keris"
	
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
	
	# FLIP HITBOX JUGA!
	# Agar saat hadap kiri, hitbox pindah ke kiri
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
		is_attacking = false
		
		# MATIKAN HITBOX
		# Agar kalau jalan biasa tidak membunuh musuh
		attack_area.monitoring = false
		
		state = weapon + "_idle"
		UpdateAnimation()

func update_hearts():
	# Loop sebanyak jumlah slot hati yang ada di UI
	for i in range(heart_list.size()):
		# Logika:
		# Jika index saat ini (i) kurang dari jumlah darah (health), maka hati aktif.
		# Contoh: Health = 2.
		# i=0 (Hati ke-1): 0 < 2 -> TRUE (Show)
		# i=1 (Hati ke-2): 1 < 2 -> TRUE (Show)
		# i=2 (Hati ke-3): 2 < 2 -> FALSE (Hide)
		
		if i < health:
			heart_list[i].visible = true # Tampilkan hati
		else:
			heart_list[i].visible = false # Sembunyikan hati (atau ganti tekstur hati kosong)
