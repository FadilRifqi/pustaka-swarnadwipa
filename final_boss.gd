class_name FinalBoss
extends CharacterBody2D

# --- STATS BOSS ---
@export var max_health: int = 1
var health: int = max_health
@export var damage_normal: int = 5
@export var damage_enrage: int = 8 # Damage saat marah
var start_position : Vector2  

# Movement AI
@export var move_speed: float = 100.0
@export var run_speed: float = 160.0 # Kecepatan saat fase 2
@export var gravity: float = 980.0
@export var chase_distance: float = 400.0
@export var attack_range: float = 120.0
@export var boss_scale: float = 5.0

# Node References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: Player = $"../Player"
@onready var health_bar: ProgressBar = $HealthBar
@onready var attack_area: Area2D = $AttackArea

# Detectors (Untuk lompat)
@onready var detectors: Node2D = $Detectors
@onready var wall_check: RayCast2D = $Detectors/WallCheck
@onready var gap_check: RayCast2D = $Detectors/GapCheck
@export var jump_force: float = -600.0

# States
var is_dead: bool = false
var is_attacking: bool = false
var is_hurt: bool = false
var is_enraged: bool = false # Fase 2
var hurt_tween: Tween

signal boss_defeated

func _ready() -> void:
	start_position = get_position_delta()
	health = max_health
	add_to_group("enemies")
	scale = Vector2(boss_scale, boss_scale)
	
	# Setup Health Bar
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = true
	
	# Setup Hitbox
	attack_area.monitoring = false
	if not attack_area.body_entered.is_connected(_on_attack_area_entered):
		attack_area.body_entered.connect(_on_attack_area_entered)
	
	# Setup Animasi
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if not is_dead:
		# Cek Fase Marah (HP < 50%)
		if health <= (max_health / 2) and not is_enraged:
			enter_enrage_mode()

		# PRIORITAS STATE
		if is_hurt:
			velocity.x = 0
		elif is_attacking:
			velocity.x = 0
		elif player:
			var distance = global_position.distance_to(player.global_position)
			var direction_x = sign(player.global_position.x - global_position.x)
			
			# A. SERANG
			if distance <= attack_range:
				velocity.x = 0
				start_attack()
				
			# B. KEJAR
			elif distance <= chase_distance:
				# Kecepatan berubah jika Enrage
				var current_speed = run_speed if is_enraged else move_speed
				velocity.x = direction_x * current_speed
				
				handle_flip(velocity.x)
				
				# Logika Lompat
				if is_on_floor():
					var wall = wall_check.is_colliding() if wall_check else false
					var gap = not gap_check.is_colliding() if gap_check else false
					if wall or gap:
						velocity.y = jump_force
			
			# C. DIAM
			else:
				go_back_to_start_position()
				health = max_health

			# Trigger Musik Boss saat mengejar
			if distance <= chase_distance and velocity.x != 0:
				if get_parent().has_method("switch_to_boss_music"):
					get_parent().switch_to_boss_music()

	else:
		velocity.x = 0

	move_and_slide()
	update_animation()

func handle_flip(vel_x: float) -> void:
	if vel_x != 0:
		var is_left = vel_x < 0
		animated_sprite.flip_h = is_left
		if is_left:
			attack_area.scale.x = -1
			if detectors: detectors.scale.x = -1
		else:
			attack_area.scale.x = 1
			if detectors: detectors.scale.x = 1

func go_back_to_start_position():
	#var direction_x = sign(get_position_delta() - start_position)
	var direction_x = sign(start_position.x - global_position.x)
	print(global_position)
	velocity.x = direction_x * move_speed
	print(direction_x)
	if velocity.x != 0:
		var is_moving_left = velocity.x < 0
		animated_sprite.flip_h = is_moving_left
		if is_moving_left:
			attack_area.scale.x = -1
			detectors.scale.x = -1 # Balik arah detektor
		else:
			attack_area.scale.x = 1
			detectors.scale.x = 1
		if is_on_floor():
			var wall_detected = wall_check.is_colliding() if wall_check else false
			var gap_detected = not gap_check.is_colliding() if gap_check else false
					
			# Jika ada tembok atau ada jurang, LOMPAT
			if wall_detected or gap_detected:
				velocity.y = jump_force

func enter_enrage_mode():
	is_enraged = true
	print("FINAL BOSS ENRAGED!")
	modulate = Color(1.5, 0.5, 0.5) # Jadi agak merah menyala permanen

func start_attack() -> void:
	if is_attacking: return
	is_attacking = true
	attack_area.monitoring = false 

# --- HITBOX TIMING ---
func _on_frame_changed() -> void:
	if animated_sprite.animation == "attack":
		# Sesuaikan frame pukul (misal frame 4)
		if animated_sprite.frame >= 9 and animated_sprite.frame <= 10:
			attack_area.monitoring = true

func _on_attack_area_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self and body is Player:
		# Damage lebih sakit jika Enrage
		var dmg = damage_enrage if is_enraged else damage_normal
		
		body.take_damage(dmg, self)
		attack_area.call_deferred("set_monitoring", false)

# --- DAMAGE & DEATH ---
func take_damage(amount: int, source: Node2D = null) -> void:
	if is_dead: return
	
	health -= amount
	if health_bar: health_bar.value = health
	print("Final Boss HP: ", health)
	
	if health <= 0:
		die()
	else:
		# Boss ini jarang stun (Hard mode), hanya flash merah
		# Kecuali damage besar
		
		var stun_chance = 0.3 # 30% peluang stun
		if randf() < stun_chance:
			is_hurt = true
			is_attacking = false
			attack_area.monitoring = false
			
			if hurt_tween: hurt_tween.kill()
			hurt_tween = create_tween()
			
			modulate = Color.RED
			hurt_tween.tween_property(self, "modulate", Color.WHITE if not is_enraged else Color(1.5, 0.5, 0.5), 0.2)
			hurt_tween.tween_callback(func(): is_hurt = false)
		else:
			# Hanya flash tanpa stop gerak
			var tween = create_tween()
			tween.tween_property(self, "modulate", Color.RED, 0.1)
			tween.tween_property(self, "modulate", Color.WHITE if not is_enraged else Color(1.5, 0.5, 0.5), 0.1)

func die() -> void:
	if is_dead: return
	is_dead = true
	
	if health_bar: health_bar.visible = false
	attack_area.monitoring = false
	velocity = Vector2.ZERO

	
	if get_parent().has_method("switch_to_level_music"):
		get_parent().switch_to_level_music()
	
	if get_parent().has_method("start_ending_sequence"):
		get_parent().start_ending_sequence()
	else:
		print("ERROR: Fungsi 'on_final_boss_defeated' tidak ditemukan di Parent (Playground)!")
	
	# Drop Item Spesial atau Tamat Game
	if player and player.has_method("add_money"):
		player.add_money(100) # Hadiah besar
		
	update_animation()
	

# --- ANIMATION ---
func update_animation() -> void:
	var anim = "idle"
	
	if is_dead: anim = "die"
	elif is_hurt: anim = "hurt"
	elif is_attacking: anim = "attack"
	elif velocity.x != 0: anim = "run" # Pakai animasi Lari
	
	if animated_sprite.animation != anim:
		if animated_sprite.sprite_frames.has_animation(anim):
			animated_sprite.play(anim)

func _on_animation_finished() -> void:
	var anim = animated_sprite.animation
	if anim == "attack":
		is_attacking = false
		attack_area.monitoring = false
	elif anim == "hurt":
		is_hurt = false
	elif anim == "die":
		# Slow motion effect saat boss mati (Cinematic)
		Engine.time_scale = 0.5
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 3.0)
		await tween.finished
		Engine.time_scale = 1.0 # Balikin normal
		queue_free()
		await get_tree().create_timer(4.0)
		get_tree().change_scene_to_file("res://CutSceneAkhir.tscn")
