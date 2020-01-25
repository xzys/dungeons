#!/usr/bin/env python3
import random

class CaveParams:
    def __init__(self,
            width=0,
            height=0,
            fill_chance=0.45,
            ):
        self.width = width
        self.height = height
        self.fill_chance = fill_chance

disp_map = {
    0: '..',
    1: '##',
    2: 'xx',
    }
def print_cave(tiles, raw=False):
    for row in tiles:
        for t in row:
            c = None
            if raw:
                c = '{:>2}'.format(t)
            else:
                c = disp_map[t] if t in disp_map else '{:<2}'.format(t)
            print(c, end='')
        print()
    print()

def clone_tiles(tiles):
    return [[tiles[y][x] 
        for x in range(len(tiles[0]))] 
        for y in range(len(tiles))]

in_range = lambda params, nx, ny: not (
        nx < 0 or nx > params.width - 1 or 
        ny < 0 or ny > params.height - 1)

def count_neighbors(params, tiles, x, y):
    c = 0
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            if dx == 0 and dy == 0:
                continue

            nx, ny = x + dx, y + dy
            if not in_range(params, nx, ny):
                continue
            if tiles[ny][nx] == 1:
                c += 1
    return c

def step_cells(params, tiles, rule):
    new_tiles = clone_tiles(tiles)
    for y in range(params.height):
        for x in range(params.width):
            c = count_neighbors(params, tiles, x, y)
            new_tiles[y][x] = 1 if rule(c) else 0

    return new_tiles

def flood_fill(params, tiles, start_y, start_x):
    found = [(start_y, start_x)]
    searching = [(start_y, start_x)]

    while len(searching) > 0:
        y, x = searching.pop()
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nx, ny = x + dx, y + dy
            if not in_range(params, nx, ny):
                pass
            elif (ny, nx) in found:
                pass
            elif tiles[ny][nx] == 0:
                searching.append((ny,nx))
                found.append((ny,nx))
    return found

def find_sections(params, tiles):
    sections = []
    filled = []

    for y in range(params.height):
        for x in range(params.width):
            if tiles[y][x] == 0 and (y, x) not in filled:
                sec = flood_fill(params, tiles, y, x)
                sections.append(sec)
                filled.extend(sec)
    return sections

def fill_edges(params, tiles, n):
    for i in range(n):
        for x in range(params.width - i*2):
            tiles[i][x+i] = 1
        for x in range(params.width - i*2):
            tiles[params.height - 1 - i][x+i] = 1
        for y in range(params.height - i*2):
            tiles[y+i][i] = 1
        for y in range(params.height - i*2):
            tiles[y+i][params.width - 1 - i] = 1

def gen_cave(params):
    tiles = [
        [1 if random.random() <= params.fill_chance else 0
            for y in range(params.width)]
        for x in range(params.height)]

    for i in range(5):
        tiles = step_cells(params, tiles, lambda c: c >= 5 or c < 2)
    fill_edges(params, tiles, 2)
    for i in range(3):
        tiles = step_cells(params, tiles, lambda c: c >= 4)

    sections = find_sections(params, tiles)
    sections = sorted(sections, key=len, reverse=True)
    for sec in sections[1:]:
        for y, x in sec:
            tiles[y][x] = 1

    print_cave(tiles)
    assigned = assign_tiles(params, tiles)
    print_cave(assigned, raw=True)


tilemap = {
        'e': -1,
        'f': 0,
        'tl': 1,
        'tr': 2,
        'bl': 3,
        'br': 4,
        }
tileset = {
        (0, 0, 0, 0): ('e', 'e', 'e', 'e'),
        (1, 1, 1, 1): ('f', 'f', 'f', 'f'),
        (1, 0, 0, 0): ('tl', 'e', 'e', 'e'),
        (0, 1, 0, 0): ('e', 'tr', 'e', 'e'),
        (0, 0, 1, 0): ('e', 'e', 'br', 'e'),
        (0, 0, 0, 1): ('e', 'e', 'e', 'bl'),
        (1, 1, 0, 0): ('f', 'f', 'e', 'e'),
        (0, 1, 1, 0): ('e', 'f', 'f', 'e'),
        (0, 0, 1, 1): ('e', 'e', 'f', 'f'),
        (1, 0, 0, 1): ('f', 'e', 'e', 'f'),
        (0, 1, 1, 1): ('br', 'f', 'f', 'f'),
        (1, 0, 1, 1): ('f', 'bl', 'f', 'f'),
        (1, 1, 0, 1): ('f', 'f', 'tl', 'f'),
        (1, 1, 1, 0): ('f', 'f', 'f', 'tr'),
        (1, 0, 1, 0): ('f', 'bl', 'f', 'tr'),
        (0, 1, 0, 1): ('f', 'f', 'f', 'f'),
        }
def assign_tiles(params, tiles):
    f = lambda y, x: tiles[y][x] if in_range(params, x, y) else 1
    new_tiles = clone_tiles(tiles) 
    
    for x in range(0, params.width, 2):
        for y in range(0, params.height, 2):
            a = (tiles[y][x], tiles[y][x+1], tiles[y+1][x+1], tiles[y+1][x])
            xs = tileset[a]
            new_tiles[y][x] = tilemap[xs[0]]
            new_tiles[y][x+1] = tilemap[xs[1]]
            new_tiles[y+1][x+1] = tilemap[xs[2]]
            new_tiles[y+1][x] = tilemap[xs[3]]
    return new_tiles
            

if __name__ == '__main__':
    c = gen_cave(CaveParams(
        width=80,
        height=60,
        fill_chance=0.45,
        ))
