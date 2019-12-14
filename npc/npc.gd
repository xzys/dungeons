extends "res://common/character.gd"

export (int) var SPEED = 100
export (float, 0, 1.0) var ACCELERATION = 0.10

export (float) var MIN_WALK_ANIM_SPEED = 0.25
export (float) var MAX_WALK_ANIM_SPEED = 2

const STATE_IDLE = 0
const STATE_WALKING = 1
const STATE_DYING = 2

onready var anim_player = $AnimationPlayer

var state = STATE_IDLE

func _ready():
	# what sprites to show during which animations
	sprites = {
		"idle": $SpriteIdle,
		"run": $SpriteRun,
		"dying": $SpriteDying,
		}
	anim = "fall"


func _physics_process(delta):
	var new_anim = anim
	var new_facing = facing
	
	if state == STATE_IDLE:
		new_anim = "idle"
	elif state == STATE_WALKING:
		velocity.x = lerp(velocity.x, SPEED, ACCELERATION)
		new_anim = "run"
	
	if anim == "run":
		var anim_speed = max(MIN_WALK_ANIM_SPEED, MAX_WALK_ANIM_SPEED * abs(velocity.x / SPEED))
		anim_player.set_speed_scale(anim_speed)
	elif anim_player.get_speed_scale() != 1:
		anim_player.set_speed_scale(1)
	
	var snap = Vector2.DOWN
	
	velocity.y += GRAVITY * delta
	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, 5, 3, deg2rad(65))
	set_sprite(anim_player, new_anim, new_facing)