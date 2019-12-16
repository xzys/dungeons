extends "res://common/character.gd"

export (int) var SPEED = 500
export (int) var AIR_SPEED = 250
export (int) var JUMP_SPEED = 400
export (int) var JUMP_HOLD_SPEED = 1000
export (float, 0, 1.0) var ACCELERATION = 0.10

export (float) var MIN_RUN_ANIM_SPEED = 1
export (float) var MAX_RUN_ANIM_SPEED = 2


export (float) var ATTACK1_SPEED = 1.25
export (int) var ATTACK1_DAMAGE = 10

export (float) var ATTACK2_SPEED = 1
export (int) var ATTACK2_DAMAGE = 20

onready var anim_player = $AnimationPlayer

func _ready():
	# what sprites to show during which animations
	sprites = {
		"idle": $SpriteIdle,
		"run": $SpriteRun,
		"jump": $SpriteJumpAndFall,
		"fall": $SpriteJumpAndFall,
		"land": $SpriteJumpAndFall,
		"attack1": $SpriteAttack,
		"attack2": $SpriteAttack,
		"attack3": $SpriteAttack,
		}

var attack_anims = ["attack1", "attack2", "attack3"]


func _physics_process(delta):
	var on_floor = is_on_floor()
	var normal = (get_collision_normal() as Vector2)
	var new_anim = anim
	if new_anim == "": new_anim = "fall"
	var snap = Vector2.DOWN
	
	## inputs
	var dir = 0
	if not anim in attack_anims:
		if Input.is_action_pressed("ui_right"):
			dir += 1
		if Input.is_action_pressed("ui_left"):
			dir -= 1
	
	if dir != 0:
		var target_speed
		if on_floor:
			# on the ground, scale target speed with normal
			target_speed = dir * SPEED * abs(normal.dot(Vector2.UP))
			new_anim = "run"
		else:
			# in the air, you can move with AIR_SPEED
			# but you keep your exising speed
			target_speed = dir * max(abs(velocity.x), AIR_SPEED)
		velocity.x = lerp(velocity.x, target_speed, ACCELERATION)
	elif on_floor:
		velocity.x = lerp(velocity.x, 0, FRICTION)
	elif not on_floor:
		velocity.x = lerp(velocity.x, 0, AIR_FRICTION)
	
	# jumping
	if not anim in attack_anims:
		if on_floor and Input.is_action_just_pressed("jump"):
			# jump impulse is upward force + side force scaled to current speed
			# var jump_angle = dir * abs(velocity.x / SPEED) * Vector2(-normal.y, normal.x)
			var jump_angle = min(1, (velocity.x / SPEED)) * Vector2(-normal.y, normal.x)
			velocity = JUMP_SPEED * (normal + jump_angle)
			snap = Vector2.ZERO
			new_anim = "jump"
		elif anim == "jump" and Input.is_action_pressed("jump"):
			velocity.y += -JUMP_HOLD_SPEED * delta
	
		# attacks
		elif on_floor and Input.is_action_just_pressed("attack1"):
			new_anim = "attack1"
			anim_player.set_speed_scale(ATTACK1_SPEED)
		elif on_floor and Input.is_action_just_pressed("attack2"):
			new_anim = "attack2"
			anim_player.set_speed_scale(ATTACK2_SPEED)
	elif anim == "attack1" and not anim_player.is_playing():
		new_anim = "idle"
	elif anim == "attack2" and not anim_player.is_playing():
		new_anim = "idle"
		
	# falling
	if anim == "jump" and velocity.y > 0:
		new_anim = "fall"
	elif (anim == "run" or anim == "idle") and not on_floor:
		new_anim = "fall"
	# back to idle state
	elif (anim == "jump" or anim == "fall") and on_floor:
		new_anim = "land"
	elif anim == "land" and not anim_player.is_playing():
		new_anim = "idle"
	elif anim == "run" and abs(velocity.x) < SIDING_CHANGE_SPEED:
		new_anim = "idle"
	
	
	velocity.y += GRAVITY * delta
	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, 5, 3, deg2rad(65))
	set_sprite(anim_player, new_anim, calc_new_facing())
	interact_animations(anim_player, normal, velocity, on_floor, MAX_RUN_ANIM_SPEED, MIN_RUN_ANIM_SPEED, SPEED, attack_anims)

func _on_attack1(body):
	body.take_damage(ATTACK1_DAMAGE)

func _on_attack2(body):
	body.take_damage(ATTACK2_DAMAGE)
