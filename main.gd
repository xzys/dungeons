extends Node2D

onready var terrain = $terrain
onready var player = $player
onready var enemy = $skeleton

func _ready():
    randomize()
    print('starting...')
    
    var tiles = terrain.generate_cave()
    var spawn = terrain.find_spawn(tiles)
    player.position = spawn
    enemy.position = spawn