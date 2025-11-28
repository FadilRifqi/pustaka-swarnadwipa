class_name SkeletonLvl1 extends CharacterBody2D

# --- VARIABLES ---
@export var max_health: int = 5
var health: int = max_health
@export var move_speed: float = 80.0
@export var gravity: float = 980.0
@export var jump_force: float = -400.0 # Kekuatan lompat musuh
@onready var detectors: Node2D = $Detectors
@onready var wall_check: RayCast2D = $Detectors/WallCheck
@onready var gap_check: RayCast2D = $Detectors/GapCheck

# AI Settings
@export var detect_range: float = 400.0 
@export var attack_range: float = 50.0  
@onready var player: Player = $"../Player" 
@onready var health_bar: ProgressBar = $HealthBar

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

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	scale = Vector2(2.0, 2.0) 
	
	health_bar.max_value = max_health # Set batas atas bar
	health_bar.value = health         # Isi penuh di awal
	health_bar.visible = false        # (Opsional) Sembunyikan kalau darah penuh
	
	# Setup Hitbox (Mati di awal)
	attack_area.monitoring = false
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)

	if not animation_player.animation_finished.is_connected(_on_animation_player_animation_finished):
		animation_player.animation_finished.connect(_on_animation_player_animation_finished)

func _physics_process(delta: float) -> void:
	# 1. GRAVITASI
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 2. LOGIKA AI
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
				if velocity.x != 0:
					facing_right = velocity.x > 0
					var scale_x = 1 if facing_right else -1
					
					# Flip Sprite & Hitbox (Kode lama)
					walking.scale.x = scale_x
					# ... flip sprite lain ...
					attack_area.scale.x = scale_x
					
					# Flip Detectors (BARU)
					detectors.scale.x = scale_x
					
				if is_on_floor():
					# 1. Jika ada tembok di depan
					var wall_detected = wall_check.is_colliding()
					
					# 2. Jika TIDAK ada lantai di depan (Gap)
					var gap_detected = not gap_check.is_colliding()
					
					if wall_detected or gap_detected:
						print(wall_detected)
						print(gap_detected)
						print("Musuh Lompats!")
						velocity.y = jump_force
			# Diam
			else:
				velocity.x = move_toward(velocity.x, 0, move_speed)
				
			# Flip
			if velocity.x != 0:
				facing_right = velocity.x > 0
		
		# Stop gerak saat serang/sakit
		if is_attacking or is_hurt:
			velocity.x = 0
			
		# --- LOGIKA FRAME 5 (BARU) ---
		# Cek manual setiap frame
		if is_attacking:
			# Kita cek properti frame milik sprite attack
			# Pastikan AnimationPlayer kamu memang meng-animasikan properti "frame" dari node $Attack
			if attack_sprite.frame == 5:
				if not attack_area.monitoring:
					attack_area.monitoring = true
					# print("Skeleton Hitbox ON (Frame 5)")
					
	else:
		velocity.x = 0

	move_and_slide()
	update_animation()

# --- LOGIKA SERANGAN ---
func start_attack() -> void:
	if is_attacking: return
	is_attacking = true
	
	# PENTING: Matikan dulu di awal, biar nyala pas frame 5 nanti
	attack_area.monitoring = false 

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self:
		# Skeleton memberi damage 1 (atau ubah sesuai keinginan)
		body.take_damage(0.25, self) 

# --- LOGIKA TERKENA DAMAGE ---
func take_damage(amount: int, source: Node2D = null) -> void:
	if is_dead or source.is_in_group("enemies"): return
	
	health -= amount
	print("Skeleton HP: ", health)
	
	health_bar.value = health
	health_bar.visible = true # Munculkan bar saat kena pukul
	
	if health <= 0:
		die()
	else:
		is_hurt = true
		is_attacking = false
		attack_area.monitoring = false
		
		# Knockback
		if source:
			var knockback_dir = sign(global_position.x - source.global_position.x)
			velocity.x = knockback_dir * 100
			velocity.y = -150

func die() -> void:
	if is_dead: return 
	
	is_dead = true
	attack_area.monitoring = false
	health_bar.visible = false
	velocity = Vector2.ZERO
	print("Skeleton Mati")
	update_animation()

# --- UPDATE VISUAL ---
func update_animation() -> void:
	# Hide Semua
	walking.hide(); idle.hide(); attack_sprite.hide(); die_sprite.hide(); hurt_sprite.hide()
	
	# Flip Sprite
	var scale_x = 1 if facing_right else -1
	walking.scale.x = scale_x
	idle.scale.x = scale_x
	attack_sprite.scale.x = scale_x
	die_sprite.scale.x = scale_x
	hurt_sprite.scale.x = scale_x
	
	# Flip Hitbox
	attack_area.scale.x = scale_x 
	
	# Pilih Animasi
	var anim_name = "idle"
	
	if is_dead:
		die_sprite.show()
		anim_name = "die"
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
		attack_area.monitoring = false # Matikan hitbox setelah selesai
	elif anim_name == "hurt" or anim_name == "Hurt":
		is_hurt = false
	elif anim_name == "die" or anim_name == "Die":
		queue_free()
