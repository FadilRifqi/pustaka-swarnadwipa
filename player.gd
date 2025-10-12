class_name Player extends CharacterBody2D

var heart_list : Array[TextureRect]
var health : int = 3
var cardinal_direction : Vector2 = Vector2.RIGHT
var direction : Vector2 = Vector2.ZERO
var move_speed : float = 150.0
var state : String = ""
var weapon : String = "barehand"
var last_pressed : String = ""
var next_attack : String = ""
var is_attacking : bool = false
var gravity : float = 5000
var jump_force : float = -1500
var is_jumping : bool = false
var fall_start_y : float = 0.0
var fall_time : float = 0.0
var coyote_time: float = 0.12
var jump_buffer_time: float = 0.12
var fall_gravity_multiplier: float = 2.0
var jump_cut_multiplier: float = 2.2
var apex_gravity_multiplier: float = 0.85
var apex_threshold: float = 120.0

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

@onready var animation_player:AnimationPlayer = $AnimationPlayer
@onready var spear_walking:Sprite2D = $Spear_Walking
@onready var spear_idle:Sprite2D = $Spear_Idle
@onready var attack_spear_1:Sprite2D = $Spear_Attack_1
@onready var attack_spear_2:Sprite2D = $Spear_Attack_2
@onready var attack_spear_3:Sprite2D = $Spear_Attack_3
@onready var barehand_idle:Sprite2D = $Barehand_Idle
@onready var barehand_walking:Sprite2D = $Barehand_Walking
@onready var barehand_running:Sprite2D = $Barehand_Running
@onready var barehand_jumping:Sprite2D = $Barehand_Jumping
@onready var spear_running:Sprite2D = $Spear_Running
@onready var spear_jumping:Sprite2D = $Spear_Jumping


func _ready() -> void:
	var hearts_parent = $HealthLayer/HBoxContainer
	for child in hearts_parent.get_children():
		heart_list.append(child)
	


func _process(delta: float) -> void:
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	# set jump buffer saat tombol jump ditekan (diproses di physics nanti)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	# tetap panggil SetDirection / SetState untuk update visual state (tetapi
	# jangan ubah velocity di SetState)
	if SetState() == true or SetDirection() == true:
		UpdateAnimation()

	UpdateWeapon()
	#velocity = direction * move_speed

func UpdateWeapon():
	if Input.is_action_just_pressed("slot_1"):
		weapon = "spear"
		if last_pressed == "spear":
			weapon = "barehand"
			last_pressed = ""
		else:
			last_pressed = "spear"
	elif Input.is_action_just_pressed("slot_2"):
		weapon = "rencong"
		if last_pressed == "rencong":
			weapon = "barehand"
			last_pressed = ""
		else:
			last_pressed = "rencong"
	elif Input.is_action_just_pressed("slot_3"):
		weapon = "karambit"
		last_pressed = ""
		if last_pressed == "karambit":
			weapon = "barehand"
		else:
			last_pressed = "karambit"

func _physics_process(delta: float) -> void:
	# COYOTE TIMER
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	# JUMP via buffer + coyote (only here)
	if jump_buffer_timer > 0.0 and (is_on_floor() or coyote_timer > 0.0) and not is_attacking:
		# do the actual jump here
		jump_buffer_timer = 0.0
		is_jumping = true
		velocity.y = jump_force
		# set state for visuals; SetState won't set velocity now
		if weapon == "spear":
			state = "spear_jumping"
		else:
			state = "barehand_jumping"
		UpdateAnimation()

	# decrement jump buffer
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	# GRAVITY (with multipliers)
	if not is_on_floor():
		# Keep falling even while attacking in air (no freeze)
		var g := gravity
		if velocity.y < 0.0:
			# going up
			if Input.is_action_just_released("jump"):
				g *= jump_cut_multiplier
			elif absf(velocity.y) <= apex_threshold:
				g *= apex_gravity_multiplier
		else:
			# falling
			g *= fall_gravity_multiplier
		velocity.y = min(velocity.y + g * delta, 3000)
	else:
		# landing
		if is_jumping:
			is_jumping = false
			if not is_attacking:
				if weapon == "spear":
					state = "spear_idle" if direction == Vector2.ZERO else ("spear_running" if Input.is_action_pressed("run") else "spear_walking")
				else:
					state = "barehand_idle" if direction == Vector2.ZERO else ("barehand_running" if Input.is_action_pressed("run") else "barehand_walking")
				UpdateAnimation()
		#velocity.y = 0.0

	# HORIZONTAL movement
	if is_attacking:
		if is_on_floor():
			velocity.x = 0.0
		else:
			# Boleh bergerak kiri/kanan saat attack di udara
			var target := direction.x * move_speed
			var accel := 900.0
			velocity.x = move_toward(velocity.x, target, accel * delta)
	else:
		var target := direction.x * move_speed
		var accel := 1800.0 if is_on_floor() else 900.0
		velocity.x = move_toward(velocity.x, target, accel * delta)

	# finally apply movement
	move_and_slide()

func SetDirection () -> bool:
	var new_dir :Vector2 = cardinal_direction

	if direction == Vector2.ZERO:
		return false
	new_dir = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT

	if new_dir == cardinal_direction:
		return false
	cardinal_direction = new_dir
	spear_walking.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	spear_idle.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	attack_spear_1.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	attack_spear_2.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	attack_spear_3.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	barehand_idle.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	barehand_walking.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	barehand_running.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	barehand_jumping.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	spear_running.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	spear_jumping.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true

func SetState() -> bool:
	var new_state : String = state
	
	# Udara: pertahankan animasi lompat saat tidak menyerang
	if not is_on_floor() and not is_attacking:
		if weapon == "spear":
			new_state = "spear_jumping"
		elif weapon == "barehand":
			new_state = "barehand_jumping"
	if weapon == "spear":
		# Prioritas: Jump > Run > Walk (jangan timpa run dengan else dari jump)
		if Input.is_action_just_pressed("jump") and is_on_floor() and not is_attacking:
			new_state = "spear_jumping"
			is_jumping = true
			velocity.y = jump_force
		elif is_on_floor() and not is_attacking and Input.is_action_pressed("run"):
			move_speed = 250
			new_state = "spear_idle" if direction == Vector2.ZERO else "spear_running"
		elif is_on_floor() and not is_attacking:
			move_speed = 150
			new_state = "spear_idle" if direction == Vector2.ZERO else "spear_walking"
	elif weapon == "barehand":
		if Input.is_action_just_pressed("jump") and is_on_floor() and not is_attacking:
			new_state = "barehand_jumping"
			is_jumping = true
			velocity.y = jump_force
		elif is_on_floor() and not is_attacking and Input.is_action_pressed("run"):
			move_speed = 250
			new_state = "barehand_idle" if direction == Vector2.ZERO else "barehand_running"
		elif is_on_floor() and not is_attacking:
			move_speed = 150
			new_state = "barehand_idle" if direction == Vector2.ZERO else "barehand_walking"
	
	# Chain attack saat sudah menyerang
	if is_attacking and weapon == "spear":
		if state == "attack_spear_1" and Input.is_action_just_pressed("basic_hit"):
			next_attack = "attack_spear_2"
		elif state == "attack_spear_2" and Input.is_action_just_pressed("basic_hit"):
			next_attack = "attack_spear_3"
		return false
	
	# Mulai serang (boleh di udara)
	if Input.is_action_just_pressed("basic_hit") and not is_attacking and weapon == "spear":
		if state in ["spear_idle", "spear_walking", "spear_running", "spear_jumping"]:
			new_state = "attack_spear_1"
			is_attacking = true
			#if not is_on_floor():
				#velocity.y = 0  # freeze di udara
	
	if new_state == state:
		return false
	
	state = new_state
	return true

func _on_animation_player_animation_finished(anim_name: String) -> void:
	if anim_name == "attack_spear_1":
		if next_attack == "attack_spear_2":
			state = "attack_spear_2"
			is_attacking = true
			next_attack = ""
			UpdateAnimation()
		else:
			is_attacking = false
			state = "spear_idle" if is_on_floor() else "spear_jumping"
			UpdateAnimation()
	elif anim_name == "attack_spear_2":
		if next_attack == "attack_spear_3":
			state = "attack_spear_3"
			is_attacking = true
			next_attack = ""
			UpdateAnimation()
		else:
			next_attack = ""
			is_attacking = false
			state = "spear_idle" if is_on_floor() else "spear_jumping"
			UpdateAnimation()
	elif anim_name == "attack_spear_3":
		next_attack = ""
		is_attacking = false
		state = "spear_idle" if is_on_floor() else "spear_jumping"
		UpdateAnimation()

func UpdateAnimation() -> void:
	# Only play animations that exist; if spear_idle doesn't exist yet, stop so walking doesn't keep playing
	if state == "spear_idle":
		spear_idle.show()
		spear_walking.hide()
		attack_spear_1.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.hide()
		barehand_running.hide()
		barehand_jumping.hide()
		spear_running.hide()
		spear_jumping.hide()
	elif state == "attack_spear_1":
		attack_spear_1.show()
		spear_idle.hide()
		spear_walking.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.hide()
		barehand_walking.hide()
		barehand_running.hide()
		barehand_jumping.hide()
		spear_running.hide()
		spear_jumping.hide()
	elif state == "attack_spear_2":
		attack_spear_1.hide()
		spear_idle.hide()
		spear_walking.hide()
		attack_spear_2.show()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.hide()
		barehand_walking.hide()
		barehand_running.hide()
		barehand_jumping.hide()
		spear_running.hide()
		spear_jumping.hide()
	elif state == "attack_spear_3":
		attack_spear_1.hide()
		spear_idle.hide()
		spear_walking.hide()
		attack_spear_2.hide()
		attack_spear_3.show()
		barehand_idle.hide()
		barehand_walking.hide()
		barehand_walking.hide()
		barehand_running.hide()
		barehand_jumping.hide()
		spear_running.hide()
		spear_jumping.hide()
	elif state == "spear_walking":
		spear_walking.show()
		attack_spear_1.hide()
		spear_idle.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.hide()
		barehand_walking.hide()
		barehand_running.hide()
		barehand_jumping.hide()
		spear_running.hide()
		spear_jumping.hide()
	elif state == "barehand_idle":
		spear_walking.hide()
		attack_spear_1.hide()
		spear_idle.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.show()
		barehand_walking.hide()
		barehand_walking.hide()
		barehand_running.hide()
		barehand_jumping.hide()
		spear_running.hide()
		spear_jumping.hide()
	elif state == "barehand_walking":
		spear_walking.hide()
		attack_spear_1.hide()
		spear_idle.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.show()
		barehand_running.hide()
		barehand_jumping.hide()
		spear_running.hide()
		spear_jumping.hide()
	elif state == "barehand_running":
		spear_walking.hide()
		attack_spear_1.hide()
		spear_idle.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.hide()
		barehand_walking.hide()
		barehand_running.show()
		barehand_jumping.hide()
		spear_running.hide()
		spear_jumping.hide()
	elif state == "barehand_jumping":
		spear_walking.hide()
		attack_spear_1.hide()
		spear_idle.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.hide()
		barehand_walking.hide()
		barehand_running.hide()
		barehand_jumping.show()
		spear_running.hide()
		spear_jumping.hide()
	elif state == "spear_running":
		spear_walking.hide()
		attack_spear_1.hide()
		spear_idle.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.hide()
		barehand_walking.hide()
		barehand_running.hide()
		barehand_jumping.hide()
		spear_running.show()
		spear_jumping.hide()
	elif state == "spear_jumping":
		spear_walking.hide()
		attack_spear_1.hide()
		spear_idle.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.hide()
		barehand_walking.hide()
		barehand_running.hide()
		barehand_jumping.hide()
		spear_running.hide()
		spear_jumping.show()
	else:
		spear_walking.hide()
		attack_spear_1.hide()
		spear_idle.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.hide()
		barehand_running.hide()
		barehand_jumping.hide()
		spear_running.hide()
		spear_jumping.hide()
	animation_player.play(state)
