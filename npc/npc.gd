extends "res://common/character.gd"

export (int) var SPEED = 30
export (float, 0, 1.0) var ACCELERATION = 0.025

export (float) var MIN_RUN_ANIM_SPEED = 0.1
export (float) var MAX_RUN_ANIM_SPEED = 1.5

const STATE_IDLE = 0
const STATE_WALKING = 1
const STATE_DYING = 2

onready var anim_player = $AnimationPlayer

func _ready():
	# what sprites to show during which animations
	sprites = {
		"idle": $SpriteIdle,
		"run": $SpriteRun,
		"dying": $SpriteDying,
		}

var state = STATE_IDLE
var mask_tiles = 1
var mask_player = 2
var dir = -1
var attention = 0

export (float) var PLAYER_ATTENTION = 5
export (float) var SENSE_FRONT = 300
export (float) var SENSE_BEHIND = 150

func _physics_process(delta):
	var new_anim = anim
	var on_floor = is_on_floor()
	var normal = (get_collision_normal() as Vector2)
	
	if state == STATE_IDLE:
		new_anim = "idle"
		
	elif state == STATE_WALKING:
		velocity.x = lerp(velocity.x, dir * SPEED, ACCELERATION)
		new_anim = "run"
		
		if cast_ray(Vector2(facing * 50, 0), mask_tiles):
			dir = facing * -1
		
		attention = attention - delta
		if attention < 0:
			velocity.x = 0
			state = STATE_IDLE
	
	# if player in front of you start walking
	if cast_ray(Vector2(facing * SENSE_FRONT, 0), mask_player):
		state = STATE_WALKING
		dir = facing
		attention = PLAYER_ATTENTION
	# otherwise if player behind you (less distance), turn around
	elif cast_ray(Vector2(-facing * SENSE_BEHIND, 0), mask_player):
		state = STATE_WALKING
		dir = -facing
		attention = PLAYER_ATTENTION
	
	var snap = Vector2.DOWN
	velocity.y += GRAVITY * delta
	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, 5, 3, deg2rad(65))
	set_sprite(anim_player, new_anim, calc_new_facing())
	interact_animations(anim_player, normal, velocity, on_floor, MAX_RUN_ANIM_SPEED, MIN_RUN_ANIM_SPEED, SPEED)