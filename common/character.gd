extends KinematicBody2D

export (int) var GRAVITY = 2000
export (float, 0, 1.0) var FRICTION = 0.10
export (float, 0, 1.0) var AIR_FRICTION = 0.02
export (int) var SIDING_CHANGE_SPEED = 10

var sprites = {}
var velocity = Vector2.ZERO
var anim = ""
var facing = 1


func set_sprite_visible(name):
	for k in sprites.keys():
		if k != name:
			(sprites[k]).visible = false
	sprites[name].visible = true

func set_sprite(anim_player, new_anim, new_facing):
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
