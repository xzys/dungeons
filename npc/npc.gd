extends KinematicBody2D

export (int) var SPEED = 100

export (int) var GRAVITY = 2000
export (float, 0, 1.0) var FRICTION = 0.10
export (float, 0, 1.0) var ACCELERATION = 0.20

export (float) var MIN_WALK_ANIM_SPEED = 0.25
export (float) var MAX_WALK_ANIM_SPEED = 2

const STATE_IDLE = 0
const STATE_WALKING = 1
const STATE_DYING = 2

onready var anim_player = $AnimationPlayer
# what sprites to show during which animations
onready var sprites = {
	"idle": $SpriteIdle,
	"walk": $SpriteWalk,
	"dying": $SpriteDying,
	}

var state = STATE_IDLE
var velocity = Vector2.ZERO
var anim = ""
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

func _physics_process(delta):
	var new_anim = anim
	var new_facing = facing
	
	if state == STATE_IDLE:
		new_anim = "idle"
	elif state == STATE_WALKING:
		velocity.x = lerp(velocity.x, SPEED, ACCELERATION)
		new_anim = "walk"
	
	if anim == "walk":
		var anim_speed = max(MIN_WALK_ANIM_SPEED, MAX_WALK_ANIM_SPEED * abs(velocity.x / SPEED))
		anim_player.set_speed_scale(anim_speed)
	elif anim_player.get_speed_scale() != 1:
		anim_player.set_speed_scale(1)
	
	var snap = Vector2.DOWN
	
	velocity.y += GRAVITY * delta
	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, 5, 3, deg2rad(65))
	set_sprite(new_anim, new_facing)