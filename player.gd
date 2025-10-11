class_name Player extends CharacterBody2D

var cardinal_direction : Vector2 = Vector2.RIGHT
var direction : Vector2 = Vector2.ZERO
var move_speed : float = 150.0
var state : String = ""
var weapon : String = "barehand"
var last_pressed : String = ""
var next_attack : String = ""
var is_attacking : bool = false


@onready var animation_player:AnimationPlayer = $AnimationPlayer
@onready var spear_walking:Sprite2D = $Spear_Walking
@onready var spear_idle:Sprite2D = $Spear_Idle
@onready var attack_spear_1:Sprite2D = $Spear_Attack_1
@onready var attack_spear_2:Sprite2D = $Spear_Attack_2
@onready var attack_spear_3:Sprite2D = $Spear_Attack_3
@onready var barehand_idle:Sprite2D = $Barehand_Idle
@onready var barehand_walking:Sprite2D = $Barehand_Walking

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	direction.x = Input.get_action_strength("right") -  Input.get_action_strength("left")
	if SetState() == true || SetDirection() == true:
		UpdateAnimation()
	UpdateWeapon()
	velocity = direction * move_speed

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
	if not is_attacking:
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
	return true

func SetState() -> bool:
	var new_state : String 
	
	if weapon == "spear":
		new_state = "spear_idle" if direction == Vector2.ZERO else "spear_walking"
	elif weapon == "barehand":
		new_state = "barehand_idle" if direction == Vector2.ZERO else "barehand_walking"
	
	if is_attacking:
		if weapon == "spear":
			if state == "attack_spear_1" and Input.is_action_just_pressed("basic_hit") :
				next_attack = "attack_spear_2"
			elif state == "attack_spear_2" and Input.is_action_just_pressed("basic_hit") :
				next_attack = "attack_spear_3"
		#print(next_attack)
		#print(is_attacking)
		#print(state)
		return false

	if Input.is_action_just_pressed("basic_hit") :
		if  not is_attacking:
			if weapon == "spear":
				if state == "spear_idle" or state == "spear_walking":
					new_state = "attack_spear_1"
					is_attacking = true
		#else:
			#if state == "attack_spear_1":
				#next_attack = "attack_spear_2"



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
			state = "spear_idle"
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
			state = "spear_idle"
			UpdateAnimation()
	elif anim_name == "attack_spear_3":
		next_attack = ""
		is_attacking = false
		state = "spear_idle"
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
	elif state == "attack_spear_1":
		attack_spear_1.show()
		spear_idle.hide()
		spear_walking.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.hide()
	elif state == "attack_spear_2":
		attack_spear_1.hide()
		spear_idle.hide()
		spear_walking.hide()
		attack_spear_2.show()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.hide()
	elif state == "attack_spear_3":
		attack_spear_1.hide()
		spear_idle.hide()
		spear_walking.hide()
		attack_spear_2.hide()
		attack_spear_3.show()
		barehand_idle.hide()
		barehand_walking.hide()
	elif state == "spear_walking":
		spear_walking.show()
		attack_spear_1.hide()
		spear_idle.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.hide()
	elif state == "barehand_idle":
		spear_walking.hide()
		attack_spear_1.hide()
		spear_idle.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.show()
		barehand_walking.hide()
	elif state == "barehand_walking":
		spear_walking.hide()
		attack_spear_1.hide()
		spear_idle.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.show()
	else:
		spear_walking.hide()
		attack_spear_1.hide()
		spear_idle.hide()
		attack_spear_2.hide()
		attack_spear_3.hide()
		barehand_idle.hide()
		barehand_walking.hide()
	animation_player.play(state)
