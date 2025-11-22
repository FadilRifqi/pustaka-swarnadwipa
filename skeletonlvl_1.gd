class_name SkeletonLvl1 extends CharacterBody2D

# --- VARIABLES ---
@export var max_health: int = 5
var health: int = max_health
@export var move_speed: float = 80.0
@export var gravity: float = 980.0

# AI Settings
@export var detect_range: float = 400.0 
@export var attack_range: float = 50.0  
@onready var player: Player = $"../Player" 

# Nodes
@onready var attack_area: Area2D = $AttackArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Sprites
@onready var walking: Sprite2D = $Walking
@onready var idle: Sprite2D = $Idle
@onready var attack_sprite: Sprite2D = $Attack 
@onready var die_sprite: Sprite2D = $Die
@onready var hurt_sprite: Sprite2D = $Hurt

# States
var is_dead: bool = false
var is_attacking: bool = false
var is_hurt: bool = false
var facing_right: bool = true
@export var char_scale : float = 2.0

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	scale = Vector2(char_scale,char_scale )
	
	# Setup Hitbox & Signal
	attack_area.monitoring = false
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)

	if not animation_player.animation_finished.is_connected(_on_animation_player_animation_finished):
		animation_player.animation_finished.connect(_on_animation_player_animation_finished)

func _physics_process(delta: float) -> void:
	# 1. GRAVITASI (Selalu jalan, bahkan saat mati, supaya mayat jatuh)
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 2. LOGIKA AI (Hanya jalan jika TIDAK MATI)
	if not is_dead:
		if player and not is_hurt and not is_attacking:
			var distance = global_position.distance_to(player.global_position)
			var direction_x = sign(player.global_position.x - global_position.x)
			
			# Serang
			if distance <= attack_range:
				velocity.x = 0
				start_attack()
			# Kejar
			elif distance <= detect_range:
				velocity.x = direction_x * move_speed
			# Diam
			else:
				velocity.x = move_toward(velocity.x, 0, move_speed)
				
			# Flip
			if velocity.x != 0:
				facing_right = velocity.x > 0
		
		# Stop gerak saat serang/sakit
		if is_attacking or is_hurt:
			velocity.x = 0
	else:
		# Jika mati, pastikan diam (tidak meluncur)
		velocity.x = 0

	move_and_slide()
	
	# 3. UPDATE ANIMASI (Wajib dipanggil meski mati)
	update_animation()

func start_attack() -> void:
	if is_attacking: return
	is_attacking = true
	attack_area.monitoring = true 

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self:
		if body is Player:
			body.take_damage(2)

func take_damage(amount: int) -> void:
	if is_dead: return
	
	health -= amount
	print("Skeleton HP: ", health)
	
	if health <= 0:
		die()
	else:
		is_hurt = true
		is_attacking = false
		attack_area.monitoring = false
		
		# Knockback
		if player:
			var knockback_dir = sign(global_position.x - player.global_position.x)
			velocity.x = knockback_dir * 200
			velocity.y = -150

func die() -> void:
	if is_dead: return # Cegah mati 2 kali
	
	is_dead = true
	attack_area.monitoring = false
	velocity = Vector2.ZERO
	print("Skeleton Mati")
	
	# Paksa update animasi sekali saat mati
	update_animation()

func update_animation() -> void:
	# Hide Semua
	walking.hide(); idle.hide(); attack_sprite.hide(); die_sprite.hide(); hurt_sprite.hide()
	
	# Flip
	var scale_x = 1 if facing_right else -1
	walking.scale.x = scale_x
	idle.scale.x = scale_x
	attack_area.scale.x = scale_x
	attack_sprite.scale.x = scale_x
	die_sprite.scale.x = scale_x
	hurt_sprite.scale.x = scale_x
	
	# Pilih Animasi
	var anim_name = "idle"
	
	if is_dead:
		die_sprite.show()
		anim_name = "die" # Pastikan nama di AnimationPlayer: "die"
	elif is_hurt:
		hurt_sprite.show()
		anim_name = "hurt"
	elif is_attacking:
		attack_sprite.show()
		anim_name = "attack"
	elif velocity.x != 0:
		walking.show()
		anim_name = "walking" 
	else:
		idle.show()
		anim_name = "idle"
	
	# Play
	if animation_player.current_animation != anim_name:
		if animation_player.has_animation(anim_name):
			animation_player.play(anim_name)

func _on_animation_player_animation_finished(anim_name: String) -> void:
	if anim_name == "attack" or anim_name == "Attack": 
		is_attacking = false
		attack_area.monitoring = false
	elif anim_name == "hurt" or anim_name == "Hurt":
		is_hurt = false
	elif anim_name == "die" or anim_name == "Die":
		# Hapus mayat setelah animasi mati selesai
		queue_free()
