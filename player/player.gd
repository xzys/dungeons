extends "res://common/character.gd"

export (int) var SPEED = 600
export (int) var AIR_SPEED = 250
export (int) var JUMP_SPEED = 400
export (int) var JUMP_HOLD_SPEED = 1000
export (float, 0, 1.0) var ACCELERATION = 0.05

export (float) var MIN_RUN_ANIM_SPEED = 1
export (float) var MAX_RUN_ANIM_SPEED = 2

export (int) var HEALTH = 50
export (float) var ATTACK1_SPEED = 1.25
export (int) var ATTACK1_DAMAGE = 10
export (float) var ATTACK2_SPEED = 1
export (int) var ATTACK2_DAMAGE = 20

onready var anim_player = $AnimationPlayer

func _ready():
	# what sprites to show during which animations
	sprites = {
		"idle": get_node("Sprite/SpriteIdle"),
		"run": get_node("Sprite/SpriteRun"),
		"jump": get_node("Sprite/SpriteJumpAndFall"),
		"fall": get_node("Sprite/SpriteJumpAndFall"),
		"land": get_node("Sprite/SpriteJumpAndFall"),
		"attack1": get_node("Sprite/SpriteAttack"),
		"attack2": get_node("Sprite/SpriteAttack"),
		"attack3": get_node("Sprite/SpriteAttack"),
		"hit": get_node("Sprite/SpriteRoll"),
		"dying": get_node("Sprite/SpriteDying"),
		}
	blocking_states = [STATE_ATTACK1, STATE_ATTACK2, STATE_HIT, STATE_DYING]
	state = STATE_IDLE
	health = HEALTH

enum {
	STATE_IDLE, STATE_RUN, STATE_JUMP, STATE_FALL, STATE_LAND, 
	STATE_ATTACK1, STATE_ATTACK2, STATE_HIT, STATE_DYING
	}
const anim_map = {
	STATE_IDLE: "idle",
	STATE_RUN: "run",
	STATE_JUMP: "jump",
	STATE_FALL: "fall",
	STATE_LAND: "land",
	STATE_ATTACK1: "attack1",
	STATE_ATTACK2: "attack2",
	STATE_HIT: "hit",
	STATE_DYING: "dying"
	}

func handle_inputs(on_floor, normal, delta):
	# running
	var dir = 0
	if not state in blocking_states:
		if Input.is_action_pressed("ui_right"):
			dir += 1
		if Input.is_action_pressed("ui_left"):
			dir -= 1
	
	if dir != 0:
		var target_speed
		if on_floor:
			# on the ground, scale target speed with normal
			target_speed = dir * SPEED * abs(normal.dot(Vector2.UP))
			state = STATE_RUN
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
	if not state in blocking_states:
		if on_floor and Input.is_action_just_pressed("jump"):
			# jump impulse is upward force + side force scaled to current speed
			# var jump_angle = dir * abs(velocity.x / SPEED) * Vector2(-normal.y, normal.x)
			var jump_angle = min(1, (velocity.x / SPEED)) * Vector2(-normal.y, normal.x)
			velocity = JUMP_SPEED * (normal + jump_angle)
			state = STATE_JUMP
		elif state == STATE_JUMP and Input.is_action_pressed("jump"):
			velocity.y += -JUMP_HOLD_SPEED * delta
	
		# attacks
		elif on_floor and Input.is_action_just_pressed("attack1"):
			state = STATE_ATTACK1
			anim_player.set_speed_scale(ATTACK1_SPEED)
		elif on_floor and Input.is_action_just_pressed("attack2"):
			state = STATE_ATTACK2
			anim_player.set_speed_scale(ATTACK2_SPEED)

func _on_attack1(area):
	if area.is_in_group("hitboxes"):
		var body = area.get_node("../../")
		if body != self:
			print('attack1')
			body.take_damage(ATTACK1_DAMAGE)

func _on_attack2(area):
	if area.is_in_group("hitboxes"):
		var body = area.get_node("../../")
		if body != self:
			body.take_damage(ATTACK2_DAMAGE)

func take_damage(damage):
	if state != STATE_HIT and state != STATE_DYING:
		print('player takes ', damage)
		state = STATE_HIT
		velocity.x = 0
		health -= damage
		if health <= 0:
			state = STATE_DYING

func _physics_process(delta):
	var on_floor = is_on_floor()
	var normal = (get_collision_normal() as Vector2)
	var old_state = state
	
	handle_inputs(on_floor, normal, delta)
	
	# only do remaining state transitions if we havent changed state this frame
	if state != old_state:
		pass
	elif state == STATE_ATTACK1 and not anim_player.is_playing():
		state = STATE_IDLE
	elif state == STATE_ATTACK2 and not anim_player.is_playing():
		state = STATE_IDLE
	# falling
	elif state == STATE_JUMP and velocity.y > 0:
		state = STATE_FALL
	elif (state == STATE_RUN or state == STATE_IDLE) and not on_floor:
		state = STATE_FALL
	# back to idle state
	elif (state == STATE_JUMP or state == STATE_FALL) and on_floor:
		state = STATE_LAND
	elif state == STATE_LAND and not anim_player.is_playing():
		state = STATE_IDLE
	elif state == STATE_RUN and abs(velocity.x) < SIDING_CHANGE_SPEED:
		state = STATE_IDLE
	elif state == STATE_HIT:
		if not anim_player.is_playing():
			state = STATE_IDLE
	
	var new_anim = anim_map[state]
	var snap = Vector2.DOWN
	if state == STATE_JUMP:
		snap = Vector2.ZERO
	
	velocity.y += GRAVITY * delta
	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, 5, 3, deg2rad(65))
	set_sprite(anim_player, new_anim, calc_new_facing())
	interact_animations(anim_player, normal, velocity, on_floor, MAX_RUN_ANIM_SPEED, MIN_RUN_ANIM_SPEED, SPEED)
