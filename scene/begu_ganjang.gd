class_name BeguGanjang
extends CharacterBody2D

# --- STATS BOSS ---
@export var max_health: int = 20
var health: int = max_health
@export var damage_amount: float = 1.5
@export var move_speed: float = 65.0 
@export var gravity: float = 980.0
@export_enum("None", "rencong", "keris") var drop_weapon_id: String = "None"
@export var chest_scene: PackedScene 

# AI Settings
@export var chase_distance: float = 800.0 
@export var attack_range: float = 140.0   
@export var boss_scale: float = 4.0      

# >>> TAMBAHAN: JUMP FORCE <<<
@export var jump_force: float = -400.0 

# Node References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var player: Player = $"../Player" 
@onready var health_bar: ProgressBar = $HealthBar

# >>> TAMBAHAN: DETECTORS <<<
@onready var detectors: Node2D = $Detectors
@onready var wall_check: RayCast2D = $Detectors/WallCheck
@onready var gap_check: RayCast2D = $Detectors/GapCheck

# States
var is_dead: bool = false
var is_attacking: bool = false
var is_hurt: bool = false

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	scale = Vector2(boss_scale, boss_scale)
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = false 
	
	attack_area.monitoring = false
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)

	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)

func _physics_process(delta: float) -> void:
	# 1. Gravitasi
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 2. Logika A I
	if not is_dead:
		if player and not is_hurt and not is_attacking:
			var distance = global_position.distance_to(player.global_position)
			var direction_x = sign(player.global_position.x - global_position.x)
			print(distance)
			# A. SERANG
			if distance <= attack_range:
				velocity.x = 0
				start_attack()
				
			# B. KEJAR
			elif distance <= chase_distance:
				velocity.x = direction_x * move_speed
				
				# Flip Logic
				if velocity.x != 0:
					var is_moving_left = velocity.x < 0
					animated_sprite.flip_h = is_moving_left
					
					# Flip Hitbox & Detectors
					if is_moving_left:
						attack_area.scale.x = -1
						detectors.scale.x = -1 # Balik arah detektor
					else:
						attack_area.scale.x = 1
						detectors.scale.x = 1
				
				# >>> LOGIKA LOMPAT <<<
				if is_on_floor():
					var wall_detected = wall_check.is_colliding() if wall_check else false
					var gap_detected = not gap_check.is_colliding() if gap_check else false
					
					# Jika ada tembok atau ada jurang, LOMPAT
					if wall_detected or gap_detected:
						velocity.y = jump_force
			
			# C. DIAM
			else:
				velocity.x = move_toward(velocity.x, 0, move_speed)
		
		# Stop gerak
		if is_attacking:
			velocity.x = 0
		elif is_hurt:
			velocity.x = 0
	else:
		velocity.x = 0

	move_and_slide()
	update_animation()

# ... (Sisa fungsi start_attack, damage, die, animation TETAP SAMA) ...
# (Tidak ada perubahan di bawah sini, copy-paste dari kodemu sebelumnya)

func start_attack() -> void:
	if is_attacking: return
	is_attacking = true
	attack_area.monitoring = false 

func _on_frame_changed() -> void:
	if animated_sprite.animation == "attack":
		if animated_sprite.frame >= 8 and animated_sprite.frame <= 11: 
			attack_area.monitoring = true
		else:
			attack_area.monitoring = false
			

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self:
		if body is Player:
			body.take_damage(damage_amount, self)
			attack_area.call_deferred("set_monitoring", false)

func take_damage(amount: int, source: Node2D = null) -> void:
	if is_dead: return
	health -= amount
	if health_bar: health_bar.value = health
	health_bar.visible = true
	print("BeguGanjang HP: ", health)
	
	if health <= 0:
		die()
	else:
		is_hurt = true
		is_attacking = false
		attack_area.monitoring = false
		
		if source:
			var knockback_dir = sign(global_position.x - source.global_position.x)
			velocity.x = knockback_dir * 50 
		
		modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		modulate = Color.WHITE
		await get_tree().create_timer(0.5).timeout
		is_hurt = false

func die() -> void:
	if is_dead: return
	is_dead = true
	if player and player.has_method("add_money"):
		player.add_money(8)
	attack_area.monitoring = false
	if health_bar: health_bar.visible = false
	velocity = Vector2.ZERO
	spawn_chest()
	update_animation()

func spawn_chest() -> void:
	# Cek apakah musuh ini disetting untuk menjatuhkan sesuatu
	if drop_weapon_id != "None" and chest_scene:
		
		# Cek apakah player SUDAH PUNYA senjata itu?
		# (Opsional: Kalau sudah punya, gak usah drop chest biar gak nyampah, 
		# atau tetap drop tapi isinya gold sesuai logika Chest.gd)
		if Global.unlocked_weapons[drop_weapon_id] == false:
			
			var chest_instance = chest_scene.instantiate()
			
			# Set posisi chest di tempat musuh mati
			chest_instance.global_position = global_position
			
			# Isi data chest (Kunci utamanya)
			chest_instance.weapon_reward = drop_weapon_id
			
			# Masukkan ke Level (bukan ke musuh, karena musuh bakal dihapus)
			get_parent().call_deferred("add_child", chest_instance)
			
			print("Chest Dropped: ", drop_weapon_id)

func update_animation() -> void:
	var anim_name = "idle"
	if is_dead: anim_name = "die"
	elif is_hurt: anim_name = "hurt"
	elif is_attacking: anim_name = "attack"
	elif velocity.x != 0: anim_name = "walk"
	
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _on_animation_finished() -> void:
	var anim = animated_sprite.animation
	if anim == "attack":
		is_attacking = false
		is_hurt = false
		attack_area.monitoring = false
	elif anim == "hurt":
		is_hurt = false
		is_attacking = false
	elif anim == "die":
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 2.0)
		await tween.finished
		queue_free()
