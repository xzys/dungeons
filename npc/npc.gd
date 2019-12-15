extends "res://common/character.gd"

export (int) var SPEED = 30
export (float, 0, 1.0) var ACCELERATION = 0.025

export (float) var MIN_RUN_ANIM_SPEED = 0.75
export (float) var MAX_RUN_ANIM_SPEED = 1.5

onready var anim_player = $AnimationPlayer

func _ready():
	# what sprites to show during which animations
	sprites = {
		"idle": $SpriteIdle,
		"react": $SpriteReact,
		"run": $SpriteRun,
		"attack": $SpriteAttack,
		"dying": $SpriteDying,
		}


const STATE_IDLE = 0
const STATE_REACT = 1
const STATE_WALKING = 2
const STATE_ATTACK = 3
const STATE_DYING = 4

const anim_map = {
	STATE_IDLE: "idle",
	STATE_REACT: "react",
	STATE_WALKING: "run",
	STATE_ATTACK: "attack",
	STATE_DYING: "dying"
	}

var state = STATE_IDLE
var mask_tiles = 1
var mask_player = 2
var dir = -1
var attention = 0

export (float) var PLAYER_ATTENTION = 5
export (float) var SENSE_ATTACK = 10
export (float) var SENSE_FRONT = 300
export (float) var SENSE_BEHIND = 150

func sense_player():
	# if player in front of you start walking
	# only react if you are idle
	if cast_ray(Vector2(facing * SENSE_FRONT, 0), mask_player):
		attention = PLAYER_ATTENTION
		dir = facing
		if state == STATE_IDLE:
			state = STATE_REACT
	# otherwise if player behind you (less distance), turn around
	elif cast_ray(Vector2(-facing * SENSE_BEHIND, 0), mask_player):
		attention = PLAYER_ATTENTION
		dir = -facing
		if state == STATE_IDLE:
			state = STATE_REACT

func _physics_process(delta):
	var new_anim = anim
	var on_floor = is_on_floor()
	var normal = (get_collision_normal() as Vector2)
	var start_state = state
	
	if state == STATE_IDLE:
		sense_player()
	elif state == STATE_REACT:
		if not anim_player.is_playing():
			state = STATE_WALKING
	elif state == STATE_WALKING:
		velocity.x = lerp(velocity.x, dir * SPEED, ACCELERATION)
		# go back to idle if attention reaches zero
		attention = attention - delta
		if attention < 0:
			velocity.x = 0
			state = STATE_IDLE
		
		# check can't move forward
		if cast_ray(Vector2(facing * 50, 0), mask_tiles):
			dir = facing * -1
		# check for player direcly in front
		elif cast_ray(Vector2(facing * SENSE_ATTACK, 0), mask_player):
			state = STATE_ATTACK
			velocity.x = 0
		else:
			# track player even if he walks behind you
			sense_player()
	elif state == STATE_ATTACK:
		if not anim_player.is_playing():
			state = STATE_WALKING
			
	new_anim = anim_map[state]
	
	var snap = Vector2.DOWN
	velocity.y += GRAVITY * delta
	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, 5, 3, deg2rad(65))
	set_sprite(anim_player, new_anim, calc_new_facing())
	interact_animations(anim_player, normal, velocity, on_floor, MAX_RUN_ANIM_SPEED, MIN_RUN_ANIM_SPEED, SPEED)