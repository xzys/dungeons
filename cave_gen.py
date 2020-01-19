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
def print_cave(tiles):
    for row in tiles:
        for t in row:
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
    assign_tiles(params, tiles)
    print_cave(tiles)


# these are tileset edges
"""
tileset = [
    # corner
    (1, 0, 0, 0, 0, 0, 0, 1),
    # angle
    (1, 1, 0, 0, 0, 0, 0, 1),
    # diagonal
    (1, 1, 0, 0, 0, 0, 1, 1),
    # angle-inv
    (1, 1, 1, 0, 0, 0, 1, 1),
    # half
    (1, 1, 1, 0, 0, 0, 0, 1),
    # corner-inv
    (1, 1, 1, 0, 0, 1, 1, 1),
    ]
tileset = [
    (tt+offset for tt in t)
    for t in tileset
    for offset in range(0, 8, 2)]
tileset += [
    # empty
    (0, 0, 0, 0, 0, 0, 0, 0),
    # full
    (1, 1, 1, 1, 1, 1, 1, 1),
    ]
            a = (
                f(y-1, x), f(y-1, x+1),
                f(y, x+2), f(y+1, x+2),
                f(y+2, x), f(y+2, x+1),
                f(y, x-1), f(y+1, x-1),
            )
"""
def rotate_cell(c, n):
    """rotate cell n times"""
    for i in range(n):
        c = (c[6], c[3], c[0], c[7], c[4], c[1], c[8], c[5], c[2])
    return c

tileset = [
    # corner
    (1, 0, 0, 0, 0, 0, 0, 0, 0),
    # angle
    (1, 1, 1, 1, 0, 0, 0, 0, 0),
    # diagonal
    (1, 1, 1, 1, 1, 0, 1, 0, 0),
    # angle-inv
    (1, 1, 1, 1, 1, 1, 1, 0, 0),
    # half
    (1, 1, 1, 1, 1, 1, 0, 0, 0),
    # corner-inv
    (0, 1, 1, 1, 1, 1, 1, 1, 1),
    ]
tileset = [
    rotate_cell(cell, rotation)
    for cell in tileset
    for rotation in range(4)]
"""
tileset += [
    # full
    (1, 1, 1, 1, 1, 1, 1, 1, 1),
    ]
"""
def assign_tiles(params, tiles):
    f = lambda y, x: tiles[y][x] if in_range(params, x, y) else 1

    """
    for x in range(0, params.width, 2):
        for y in range(0, params.height, 2):
            a = [
                f(y, x), f(y, x+1), f(y, x+2),
                f(y+1, x), f(y+1, x+1), f(y+1, x+2),
                f(y+2, x), f(y+2, x+1), f(y+2, x+2),
            ]
            for c in tileset:
                if a == c and c != tileset[-1]:
                    print(x, y, c)
    """

    for x in range(params.width):
        for y in range(params.height):
            a = tuple(
                f(y+dy, x+dy)
                for dy in range(-1, 2) for dx in range(-1, 2)
            )
            for i, c in enumerate(tileset):
                if a == c:
                    tiles[y][x] = i
            

if __name__ == '__main__':
    c = gen_cave(CaveParams(
        width=80,
        height=60,
        fill_chance=0.45,
        ))
