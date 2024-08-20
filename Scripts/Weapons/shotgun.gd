extends Node3D

@onready var sprite: AnimatedSprite2D = $Control/GunBase/Sprite
@onready var shoot_sound: AudioStreamPlayer3D = $ShootSound
@onready var ray_cast: RayCast3D = $raycast

var can_shoot = true
var dead = false

const sparks = preload("res://Scenes/sparks.tscn")

func _ready() -> void:
	sprite.animation_finished.connect(shoot_anim_done)

func _process(delta: float) -> void:
	if dead:
		return
	if Input.is_action_pressed("shoot"):
		shoot()

func shoot():
	if !can_shoot:
		return
	can_shoot = false
	sprite.play("shoot")
	shoot_sound.play()
	if ray_cast.is_colliding() and ray_cast.get_collider().has_method("kill"):
		ray_cast.get_collider().kill()
	elif ray_cast.is_colliding() and ray_cast.get_collider().is_in_group("Wall"):
		var sparks = sparks.instantiate()
		sparks.position = ray_cast.get_collision_point()
		get_tree().root.add_child(sparks)

func shoot_anim_done():
	can_shoot = true
	sprite.play("Idle")
