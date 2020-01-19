extends TileMap

export (int) var map_width = 80
export (int) var map_height = 60
export (float) var fill_chance = 0.45

func _ready():
    generate_cave()

var disp_map = {
    0: '..',
    1: '##',
    2: 'xx',
    }
func print_cave(tiles):
    var s = ''
    for row in tiles:
        for t in row:
             s += disp_map[t]
        s += '\n'
    print(s)


func clone_tiles(tiles):
    var new_tiles = []
    for i in range(tiles.size()):
        new_tiles.append(tiles[i].duplicate())
    return new_tiles

func in_array(y, x, arr):
    for i in range(arr.size()):
        if arr[i][0] == y and arr[i][1] == x:
            return true
    return false

func in_range(nx, ny):
    return not (nx < 0 or nx > map_width - 1 or ny < 0 or ny > map_height - 1)

func count_neighbors(tiles, x, y):
    var c = 0
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            if dx == 0 and dy == 0:
                continue
            var nx = x + dx
            var ny = y + dy
            if not in_range(nx, ny):
                continue
            if tiles[ny][nx] == 1:
                c += 1
    return c

func step_cells(tiles, rule):
    var new_tiles = clone_tiles(tiles)
    for y in range(map_height):
        for x in range(map_width):
            var c = count_neighbors(tiles, x, y)
            new_tiles[y][x] = 1 if rule.call_func(c) else 0

    return new_tiles

func flood_fill(tiles, start_y, start_x):
    var found = [[start_y, start_x]]
    var searching = [[start_y, start_x]]

    while len(searching) > 0:
        var s = searching.pop_front()
        for a in [[-1, 0], [1, 0], [0, -1], [0, 1]]:
            var ny = s[0] + a[0]
            var nx = s[1] + a[1]
            if not in_range(nx, ny):
                continue
            elif in_array(ny, nx, found):
                continue 
            if tiles[ny][nx] == 0:
                searching.append([ny,nx])
                found.append([ny,nx])
    return found

func find_sections(tiles):
    var sections = []
    var filled = []

    for y in range(map_height):
        for x in range(map_width):
            if tiles[y][x] == 0 and not in_array(y, x, filled):
                var sec = flood_fill(tiles, y, x)
                sections.append(sec)
                filled += sec
    return sections

func fill_edges(tiles, n):
    for i in range(n):
        for x in range(map_width - i*2):
            tiles[i][x+i] = 1
        for x in range(map_width - i*2):
            tiles[map_height - 1 - i][x+i] = 1
        for y in range(map_height - i*2):
            tiles[y+i][i] = 1
        for y in range(map_height - i*2):
            tiles[y+i][map_width - 1 - i] = 1

class SizeSorter:
    static func sort(a, b):
        return a.size() < b.size()

class CellRules:
    static func step_1(c):
        return c >= 5 or c < 2
    static func step_2(c):
        return c >= 4

func generate_cave():
    var tiles = []
    for y in range(map_height):
        var row = []
        for x in range(map_width):
            row.append(1 if randf() <= fill_chance else 0)
        tiles.append(row)

    for i in range(5):
        tiles = step_cells(tiles, funcref(CellRules, 'step_1'))
    fill_edges(tiles, 2)
    for i in range(3):
        tiles = step_cells(tiles, funcref(CellRules, 'step_2'))

    var sections = find_sections(tiles)
    sections.sort_custom(SizeSorter, 'sort')
    for i in range(sections.size()-1):
        var sec = sections[i]
        for s in sec:
            tiles[s[0]][s[1]] = 1