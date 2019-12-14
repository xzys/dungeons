extends "res://common/character.gd"

export (int) var SPEED = 500
export (int) var AIR_SPEED = 250
export (int) var JUMP_SPEED = 400
export (int) var JUMP_HOLD_SPEED = 1000
export (float, 0, 1.0) var ACCELERATION = 0.10

export (float) var MIN_RUN_ANIM_SPEED = 1
export (float) var MAX_RUN_ANIM_SPEED = 2

onready var anim_player = $AnimationPlayer

func _ready():
	# what sprites to show during which animations
	anim = "fall"
	sprites = {
		"idle": $SpriteIdle,
		"run": $SpriteRun,
		"jump": $SpriteJumpAndFall,
		"fall": $SpriteJumpAndFall,
		"land": $SpriteJumpAndFall,
		}

func _physics_process(delta):
	var on_floor = is_on_floor()
	var normal = (get_collision_normal() as Vector2)
	var new_anim = anim
	var new_facing = facing
	
	## inputs
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
	elif on_floor:
		velocity.x = lerp(velocity.x, 0, FRICTION)
	elif not on_floor:
		velocity.x = lerp(velocity.x, 0, AIR_FRICTION)
    	
	## animations
	if abs(velocity.x) > SIDING_CHANGE_SPEED:
		if velocity.x > 0:
			new_facing = 1
		else:
			new_facing = -1
		if on_floor:
			new_anim = "run"
	
	# scale run animation by speed
	if anim == "run":
		var anim_speed = max(MIN_RUN_ANIM_SPEED, MAX_RUN_ANIM_SPEED * abs(velocity.x / SPEED))
		anim_player.set_speed_scale(anim_speed)
	elif anim_player.get_speed_scale() != 1:
		anim_player.set_speed_scale(1)
		
	# rotate player based on normal
	if anim in ["run", "idle", "land"]:
		sprites[anim].rotation = normal.angle() + PI/2
	else:
		sprites[anim].rotation = 0
		
	# jumping
	var snap = Vector2.DOWN
	if Input.is_action_just_pressed("jump") and on_floor:
		# jump impulse is upward force + side force scaled to current speed
		# var jump_angle = dir * abs(velocity.x / SPEED) * Vector2(-normal.y, normal.x)
		var jump_angle = min(1, (velocity.x / SPEED)) * Vector2(-normal.y, normal.x)
		velocity = JUMP_SPEED * (normal + jump_angle)
		snap = Vector2.ZERO
		new_anim = "jump"
	elif anim == "jump" and Input.is_action_pressed("jump"):
		velocity.y += -JUMP_HOLD_SPEED * delta
	
	# falling
	if anim == "jump" and velocity.y > 0:
		new_anim = "fall"
	elif (anim == "run" or anim == "idle") and not on_floor:
		new_anim = "fall"
	# back to idle state
	elif (anim == "jump" or anim == "fall") and on_floor:
		new_anim = "land"
	elif anim == "land" and !anim_player.is_playing():
		new_anim = "idle"
	elif anim == "run" and abs(velocity.x) < SIDING_CHANGE_SPEED:
		new_anim = "idle"
	
	velocity.y += GRAVITY * delta
	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, 5, 3, deg2rad(65))
	set_sprite(anim_player, new_anim, new_facing)