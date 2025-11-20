class_name Player extends CharacterBody2D

# --- VARIABLES ---
var heart_list : Array[TextureRect]
var health : int = 3
var cardinal_direction : Vector2 = Vector2.RIGHT
var direction : Vector2 = Vector2.ZERO
@export var move_speed : float = 150.0
var state : String = "pedang_idle"
var weapon : String = "pedang"
var last_pressed : String = ""
var next_attack : String = ""
var is_attacking : bool = false
var gravity : float = 5000
var jump_force : float = -1500
var is_jumping : bool = false
var fall_start_y : float = 0.0
var fall_time : float = 0.0

# Jump & Dash Variables
var coyote_time: float = 0.12
var jump_buffer_time: float = 0.12
var fall_gravity_multiplier: float = 2.0
var jump_cut_multiplier: float = 2.2
var apex_gravity_multiplier: float = 0.85
var apex_threshold: float = 120.0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

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
	
	for child in hearts_parent.get_children():
		heart_list.append(child)
	
	UpdateAnimation()

func _process(delta: float) -> void:
	# 1. Input Gerak
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	# 2. Update Arah Hadap
	if direction.x != 0:
		if direction.x > 0:
			cardinal_direction = Vector2.RIGHT
		else:
			cardinal_direction = Vector2.LEFT

	# Jump Buffer
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			jump_buffer_timer = jump_buffer_time
		elif not is_attacking and not is_dashing and can_air_dash:
			_start_air_dash()

	# 3. Logic State & Weapon
	SetState()
	UpdateWeapon()
	
	# 4. Update Visual
	UpdateAnimation()

func _physics_process(delta: float) -> void:
	# COYOTE TIMER
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	# JUMP EXECUTION
	if jump_buffer_timer > 0.0 and (is_on_floor() or coyote_timer > 0.0) and not is_attacking:
		jump_buffer_timer = 0.0
		is_jumping = true
		velocity.y = jump_force
		
		# Set visual state saat lompat (Gunakan string format agar otomatis ikut senjata)
		state = weapon + "_jumping"
		UpdateAnimation()

	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	# GRAVITY
	if not is_on_floor():
		if is_dashing:
			velocity.y = 0.0
		else:
			var g := gravity
			if velocity.y < 0.0: # Naik
				if Input.is_action_just_released("jump"): g *= jump_cut_multiplier
				elif absf(velocity.y) <= apex_threshold: g *= apex_gravity_multiplier
			else: # Turun
				g *= fall_gravity_multiplier
			velocity.y = min(velocity.y + g * delta, 3000)
	else:
		# LANDING
		if is_jumping:
			is_jumping = false
			if not is_attacking:
				# Reset ke idle/run saat mendarat
				state = weapon + ("_idle" if direction == Vector2.ZERO else "_run")
				
				is_dashing = false
				can_air_dash = true
				UpdateAnimation()

	# MOVEMENT PHYSICS
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
	
	# --- LOGIKA MOVEMENT UMUM (BERLAKU UNTUK SEMUA SENJATA) ---
	# Kita gunakan string concatenation (weapon + "_action") agar tidak perlu if-else panjang
	if is_on_floor() and not is_attacking:
		if Input.is_action_just_pressed("jump"):
			new_state = weapon + "_jumping"
			is_jumping = true
			velocity.y = jump_force
		elif direction == Vector2.ZERO:
			move_speed = 150 # Reset speed saat idle
			new_state = weapon + "_idle"
		elif Input.is_action_pressed("run"):
			move_speed = 250
			new_state = weapon + "_run"
		else:
			move_speed = 150
			# Gunakan run sprite jika tidak ada walk, atau ganti ke _walk jika ada
			new_state = weapon + "_run" 
	
	# --- ATTACK LOGIC ---
	if Input.is_action_just_pressed("basic_hit") and not is_attacking:
		new_state = weapon + "_attack"
		is_attacking = true
	
	if new_state == state: return false
	state = new_state
	return true

func UpdateWeapon():
	var old_weapon = weapon
	
	if Input.is_action_just_pressed("slot_1"): weapon = "pedang" 
	elif Input.is_action_just_pressed("slot_2"): weapon = "rencong" 
	elif Input.is_action_just_pressed("slot_3"): weapon = "keris"
	
	# Jika senjata berubah, PAKSA update state visual langsung!
	if old_weapon != weapon and not is_attacking:
		# Ubah state misal dari "pedang_idle" jadi "rencong_idle"
		if "idle" in state: state = weapon + "_idle"
		elif "run" in state: state = weapon + "_run"
		elif "jumping" in state: state = weapon + "_jumping"
		UpdateAnimation()

func UpdateAnimation() -> void:
	# 1. HIDE SEMUA TERLEBIH DAHULU
	keris_attack.hide(); keris_idle.hide(); keris_run.hide()
	rencong_attack.hide(); rencong_run.hide(); rencong_idle.hide()
	pedang_attack.hide(); pedang_idle.hide(); pedang_run.hide()
	
	# 2. TENTUKAN ARAH FLIP (Untuk Sprite)
	var flip_scale = -1 if cardinal_direction == Vector2.LEFT else 1
	
	# 3. SHOW YANG SESUAI DAN APPLY FLIP
	# Pedang
	if state == "pedang_idle":
		pedang_idle.show(); pedang_idle.scale.x = flip_scale
	elif state == "pedang_run":
		pedang_run.show(); pedang_run.scale.x = flip_scale
	elif state == "pedang_attack":
		pedang_attack.show(); pedang_attack.scale.x = flip_scale
	elif state == "pedang_jumping":
		pedang_idle.show(); pedang_idle.scale.x = flip_scale # Fallback ke idle
		
	# Keris
	elif state == "keris_idle":
		keris_idle.show(); keris_idle.scale.x = flip_scale
	elif state == "keris_run":
		keris_run.show(); keris_run.scale.x = flip_scale
	elif state == "keris_attack":
		keris_attack.show(); keris_attack.scale.x = flip_scale
		
	# Rencong
	elif state == "rencong_idle":
		rencong_idle.show(); rencong_idle.scale.x = flip_scale
	elif state == "rencong_run":
		rencong_run.show(); rencong_run.scale.x = flip_scale
	elif state == "rencong_attack":
		rencong_attack.show(); rencong_attack.scale.x = flip_scale

	# 4. JALANKAN ANIMASI PLAYER (DENGAN PENGECEKAN)
	# INI KUNCI PERBAIKAN ANIMASI STUCK:
	# Hanya play jika nama animasi berbeda. Jangan restart jika sama.
	if animation_player.current_animation != state:
		if animation_player.has_animation(state):
			animation_player.play(state)

func _on_animation_player_animation_finished(anim_name: String) -> void:
	if "attack" in anim_name:
		is_attacking = false
		state = weapon + "_idle" # Reset otomatis sesuai weapon
		UpdateAnimation()
