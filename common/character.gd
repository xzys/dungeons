extends KinematicBody2D

export (int) var GRAVITY = 2000
export (float, 0, 1.0) var FRICTION = 0.10
export (float, 0, 1.0) var AIR_FRICTION = 0.02

export (int) var SIDING_CHANGE_SPEED = 10
export (float) var ROTATION_CHANGE_SPEED = 0.5

onready var main_sprite = $Sprite

var sprites = {}
var blocking_states = []
var velocity = Vector2.ZERO
var anim = ""
var facing = 1
var state = -1
var health = 0

func set_sprite_visible(name):
    for k in sprites.keys():
        if k != name:
            (sprites[k]).visible = false
    sprites[name].visible = true

func set_sprite(anim_player, new_anim, new_facing):
    if new_facing != facing or new_anim != anim:
        facing = new_facing
        main_sprite.scale.x = facing
        # sprites[new_anim].scale.x = facing
        # sprites[new_anim].position.x = facing * abs(sprites[new_anim].position.x)

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

# get new facing based on velocity
func calc_new_facing():
    if abs(velocity.x) > SIDING_CHANGE_SPEED:
        return 1 if velocity.x > 0 else -1
    else:
        return facing

func interact_animations(anim_player, normal, velocity, on_floor, max_run_anim, min_run_anim, max_speed):
    # scale run animation by speed
    if anim == "run":
        var anim_speed = max(min_run_anim, max_run_anim * abs(velocity.x / max_speed))
        anim_player.set_speed_scale(anim_speed)
    elif anim_player.get_speed_scale() != 1 and not state in blocking_states:
        anim_player.set_speed_scale(1)
        
    # rotate player based on normal
    var target_rot = 0
    if on_floor:
        target_rot = normal.angle() + PI/2
    main_sprite.rotation = lerp(sprites[anim].rotation, target_rot, ROTATION_CHANGE_SPEED)

# NOTE: this should only be used from within _physics_delta
func cast_ray(ray, mask):
    var space_state = get_world_2d().direct_space_state
    return space_state.intersect_ray(global_position, global_position + ray, [self], mask)