extends CharacterBody3D

@onready var shotgun_sprite: AnimatedSprite2D = $CanvasLayer/Control/GunBase/AnimatedSprite2D
@onready var ray_cast: RayCast3D = $raycast
@onready var shoot_sound: AudioStreamPlayer3D = $ShootSound
@onready var animation_player: AnimationPlayer = $CanvasLayer/Control/AnimationPlayer

@onready var sparks: PackedScene = preload("res://Scenes/sparks.tscn")

const MOUSE_SENS = 0.5

const MAX_VELOCITY_AIR = 0.6
const MAX_VELOCITY_GROUND = 6.0
const MAX_ACCELERATION = 10 * MAX_VELOCITY_GROUND
const GRAVITY = 15.34
const STOP_SPEED = 1.5
const JUMP_IMPULSE = sqrt(2 * GRAVITY * 0.85)

var friction = 4
var wish_jump: bool = false


var can_shoot = true
var dead = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	shotgun_sprite.animation_finished.connect(shoot_anim_done)
	$CanvasLayer/Control/DeathScreen/Panel/Button.button_up.connect(restart)

func _input(event: InputEvent) -> void:
	if dead:
		return
	#camera movement
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * MOUSE_SENS
		rotation_degrees.x -= event.relative.y * MOUSE_SENS
		rotation_degrees.x = clamp(rotation_degrees.x, -60, 60)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	if Input.is_action_just_pressed("restart"):
		restart()
	if dead:
		return
	if Input.is_action_pressed("shoot"):
		shoot()
	
	wish_jump = Input.is_action_pressed("jump")
	if velocity != Vector3(0, 0, 0):
		animation_player.play("walking")
	else:
		animation_player.pause()

func _physics_process(delta: float) -> void:
	if dead:
		return
	
	#movement
	var input_dir := Input.get_vector("left", "right", "foward", "backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	process_movement(delta, direction)

func process_movement(delta, direction):
	var wish_dir = direction.normalized()
	if is_on_floor():
		# If wish_jump is true then we won't apply any friction and allow the 
		# player to jump instantly, this gives us a single frame where we can 
		# perfectly bunny hop
		if wish_jump:
			velocity.y = JUMP_IMPULSE
			# Update velocity as if we are in the air
			velocity = update_velocity_air(wish_dir, delta)
			wish_jump = false
		else:
			velocity = update_velocity_ground(wish_dir, delta)
	else:
		# Only apply gravity while in the air
		velocity.y -= GRAVITY * delta
		velocity = update_velocity_air(wish_dir, delta)

	# Move the player once velocity has been calculated
	move_and_slide()

func accelerate(wish_dir: Vector3, max_velocity: float, delta):
	
	# Get our current speed as a projection of velocity onto the wish_dir
	var current_speed = velocity.dot(wish_dir)
	# How much we accelerate is the difference between the max speed and the current speed
	# clamped to be between 0 and MAX_ACCELERATION which is intended to stop you from going too fast
	var add_speed = clamp(max_velocity - current_speed, 0, MAX_ACCELERATION * delta)
	return velocity + add_speed * wish_dir
	
func update_velocity_ground(wish_dir: Vector3, delta):
	# Apply friction when on the ground and then accelerate
	var speed = velocity.length()
	if speed != 0:
		var control = max(STOP_SPEED, speed)
		var drop = control * friction * delta
		
		# Scale the velocity based on friction
		velocity *= max(speed - drop, 0) / speed
	
	return accelerate(wish_dir, MAX_VELOCITY_GROUND, delta)
	
func update_velocity_air(wish_dir: Vector3, delta):
	# Do not apply any friction
	return accelerate(wish_dir, MAX_VELOCITY_AIR, delta)

func restart():
	get_tree().reload_current_scene()

func shoot():
	if !can_shoot:
		return
	can_shoot = false
	shotgun_sprite.play("shoot")
	shoot_sound.play()
	if ray_cast.is_colliding() and ray_cast.get_collider().has_method("kill"):
		ray_cast.get_collider().kill()
	elif ray_cast.is_colliding():
		var sparks = sparks.instantiate()
		sparks.position = ray_cast.get_collision_point()
		$"..".add_child(sparks)

func shoot_anim_done():
	can_shoot = true
	shotgun_sprite.play("Idle")

func kill():
	dead = true
	$CanvasLayer/Control/DeathScreen.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
