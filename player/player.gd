extends KinematicBody2D

export (int) var SPEED = 500
export (int) var AIR_SPEED = 250
export (int) var JUMP_SPEED = 400
export (int) var JUMP_HOLD_SPEED = 1000
export (int) var SIDING_CHANGE_SPEED = 10

export (int) var GRAVITY = 2000
export (float, 0, 1.0) var FRICTION = 0.10
export (float, 0, 1.0) var ACCELERATION = 0.20

export (float) var MIN_RUN_ANIM_SPEED = 1
export (float) var MAX_RUN_ANIM_SPEED = 2

onready var anim_player = $AnimationPlayer
# what sprites to show during which animations
onready var sprites = {
	"idle": $SpriteIdle,
	"run": $SpriteRun,
	"jump": $SpriteJumpAndFall,
	"fall": $SpriteJumpAndFall,
	"land": $SpriteJumpAndFall,
	}

var velocity = Vector2.ZERO
var anim = "fall"
var facing = 1


func set_sprite_visible(name):
	for k in sprites.keys():
		if k != name:
			(sprites[k]).visible = false
	sprites[name].visible = true

func set_sprite(new_anim, new_facing):
	if new_facing != facing or new_anim != anim:
		facing = new_facing
		sprites[new_anim].scale.x = new_facing
		
	if new_anim != anim:
		anim = new_anim
		set_sprite_visible(anim)
		anim_player.play(anim)

func get_collision_normal():
	# TODO get collision normal closest to DOWN
	var normal = Vector2.UP
	if get_slide_count() > 0:
		normal = get_slide_collision(0).normal
	return normal

func _physics_process(delta):
	var on_floor = is_on_floor()
	var normal = (get_collision_normal() as Vector2)
	var new_anim = anim
	var new_facing = facing
	
	var dir = 0
	if Input.is_action_pressed("ui_right"):
		dir += 1
	if Input.is_action_pressed("ui_left"):
		dir -= 1
	if dir != 0:
		var target_speed
		if on_floor:
			# on the ground, scale target speed with normal
			target_speed = dir * SPEED * abs(normal.dot(Vector2.UP))
		else:
			# in the air, you can move with AIR_SPEED
			# but you keep your exising speed
			target_speed = dir * max(abs(velocity.x), AIR_SPEED)
		velocity.x = lerp(velocity.x, target_speed, ACCELERATION)
	else:
		velocity.x = lerp(velocity.x, 0, FRICTION)
		
	## animations
	
	if abs(velocity.x) > SIDING_CHANGE_SPEED:
		if velocity.x > 0:
			new_facing = 1
		else:
			new_facing = -1
		if on_floor:
			new_anim = "run"
	
	if anim == "run":
		var anim_speed = max(MIN_RUN_ANIM_SPEED, MAX_RUN_ANIM_SPEED * abs(velocity.x / SPEED))
		anim_player.set_speed_scale(anim_speed)
	elif anim_player.get_speed_scale() != 1:
		anim_player.set_speed_scale(1)
    
	## jumping
	var snap = Vector2.DOWN
	if Input.is_action_just_pressed("jump") and on_floor:
		# jump impulse is upward force + side force scaled to current speed
		# var jump_dir = dir * abs(velocity.x / SPEED) * Vector2(-normal.y, normal.x)
		var jump_dir = (velocity.x / SPEED) * Vector2(-normal.y, normal.x)
		velocity = JUMP_SPEED * (normal + jump_dir)
		snap = Vector2.ZERO
		new_anim = "jump"
	elif anim == "jump" and velocity.y > 0:
		new_anim = "fall"
	elif anim == "jump" and Input.is_action_pressed("jump"):
		velocity.y += -JUMP_HOLD_SPEED * delta
	
	# back to idle state
	elif (anim == "jump" or anim == "fall") and on_floor:
		new_anim = "land"
	elif anim == "land" and !anim_player.is_playing():
		new_anim = "idle"
	elif anim == "run" and abs(velocity.x) < SIDING_CHANGE_SPEED:
		new_anim = "idle"
	
	velocity.y += GRAVITY * delta
	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, 5, 3, deg2rad(65))
	set_sprite(new_anim, new_facing)