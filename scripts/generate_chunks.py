"""Generate mock chunk JSON files for the Akaroa demo."""
import json
import os

CHUNK_SIZE = 32

def make_tile(x, y, ground="grass_01", detail="", obj="", roof="", collision=0, trigger_type="none", trigger_data=None, light=1.0, elevation=0):
    tile = {
        "x": x,
        "y": y,
        "layers": {
            "ground": {"graphic_id": ground, "frame_count": 1, "frame_speed": 0.0},
            "detail": {"graphic_id": detail, "frame_count": 1, "frame_speed": 0.0},
            "object": {"graphic_id": obj, "frame_count": 1, "frame_speed": 0.0},
            "roof": {"graphic_id": roof, "frame_count": 1, "frame_speed": 0.0}
        },
        "collision": collision,
        "trigger": {"type": trigger_type, "data": trigger_data or {}},
        "light": light,
        "elevation": elevation
    }
    return tile

def generate_chunk_0_0():
    """Akaroa Town — safe zone with NPCs, shops, buildings."""
    tiles = []
    for y in range(CHUNK_SIZE):
        for x in range(CHUNK_SIZE):
            ground = "cobblestone_01"
            detail = ""
            obj = ""
            roof = ""
            collision = 0
            trigger_type = "none"
            trigger_data = {}
            light = 1.0

            # Town square area (center)
            if 8 <= x <= 24 and 4 <= y <= 24:
                ground = "cobblestone_01"
            else:
                ground = "grass_01"

            # Blacksmith building (12-18, 8-12)
            if 12 <= x <= 18 and 8 <= y <= 12:
                if x == 12 or x == 18 or y == 8 or y == 12:
                    obj = "stone_wall_01"
                    collision = 15  # fully blocked
                    if x == 15 and y == 12:
                        obj = "door_01"
                        collision = 0  # door is passable
                else:
                    ground = "wood_floor_01"
                    roof = "roof_tile_01"
                    light = 0.8

            # Healer building (18-24, 10-14)
            if 18 <= x <= 24 and 10 <= y <= 14:
                if x == 18 or x == 24 or y == 10 or y == 14:
                    obj = "stone_wall_01"
                    collision = 15
                    if x == 21 and y == 14:
                        obj = "door_01"
                        collision = 0
                else:
                    ground = "wood_floor_01"
                    roof = "roof_tile_02"
                    light = 0.9

            # Bank building (16-22, 4-8)
            if 16 <= x <= 22 and 4 <= y <= 8:
                if x == 16 or x == 22 or y == 4 or y == 8:
                    obj = "stone_wall_02"
                    collision = 15
                    if x == 19 and y == 8:
                        obj = "door_02"
                        collision = 0
                else:
                    ground = "marble_floor_01"
                    roof = "roof_tile_03"
                    light = 0.85

            # Fountain in town square (animated water)
            if 15 <= x <= 17 and 15 <= y <= 17:
                if x == 16 and y == 16:
                    obj = "fountain_01"
                    detail = "water_splash"
                    # animated water
                    collision = 15
                elif (x == 15 or x == 17) and (y == 15 or y == 17):
                    obj = "fountain_edge"
                    collision = 15

            # Trees along edges
            if (x < 3 or x > 28) and y % 3 == 0:
                obj = "tree_oak_01"
                collision = 15

            if (y < 2 or y > 29) and x % 4 == 0:
                obj = "tree_pine_01"
                collision = 15

            # Torch lights at night
            if (x, y) in [(10, 8), (10, 20), (22, 8), (22, 20), (16, 14), (16, 18)]:
                detail = "torch_01"
                light = 1.5

            # Zone transition to forest (east edge)
            if x == 31 and 12 <= y <= 20:
                trigger_type = "zone_transition"
                trigger_data = {"dest_x": 0, "dest_y": y, "dest_chunk_x": 1, "dest_chunk_y": 0}

            tile = make_tile(x, y, ground, detail, obj, roof, collision, trigger_type, trigger_data, light)
            tiles.append(tile)

    # Set animated fountain tile
    for t in tiles:
        if t["x"] == 16 and t["y"] == 16:
            t["layers"]["object"]["frame_count"] = 4
            t["layers"]["object"]["frame_speed"] = 0.3

    return {
        "version": 1,
        "chunk_x": 0,
        "chunk_y": 0,
        "zone_id": "akaroa_town",
        "neighbors": {"north": "0_-1", "south": "0_1", "east": "1_0", "west": "-1_0"},
        "tiles": tiles,
        "enemies": []
    }

def generate_chunk_1_0():
    """Verdant Plains — open grassland with enemies."""
    tiles = []
    for y in range(CHUNK_SIZE):
        for x in range(CHUNK_SIZE):
            ground = "grass_01"
            detail = ""
            obj = ""
            roof = ""
            collision = 0
            light = 1.0
            trigger_type = "none"
            trigger_data = {}

            # Dirt path running north-south
            if 14 <= x <= 17:
                ground = "dirt_path_01"

            # Scattered rocks
            if (x, y) in [(5, 8), (22, 3), (28, 15), (10, 25), (3, 18)]:
                obj = "rock_01"
                collision = 15

            # Scattered trees
            if (x, y) in [(2, 2), (7, 12), (25, 7), (30, 22), (12, 28), (20, 20)]:
                obj = "tree_oak_01"
                collision = 15

            # Tall grass patches
            if (x + y) % 7 == 0 and obj == "":
                detail = "tall_grass_01"

            # Flowers
            if (x * 3 + y * 5) % 13 == 0 and obj == "" and detail == "":
                detail = "wildflower_01"

            # Zone transition back to town (west edge)
            if x == 0 and 12 <= y <= 20:
                trigger_type = "zone_transition"
                trigger_data = {"dest_x": 31, "dest_y": y, "dest_chunk_x": 0, "dest_chunk_y": 0}

            tile = make_tile(x, y, ground, detail, obj, roof, collision, trigger_type, trigger_data, light)
            tiles.append(tile)

    return {
        "version": 1,
        "chunk_x": 1,
        "chunk_y": 0,
        "zone_id": "verdant_plains",
        "neighbors": {"north": "1_-1", "south": "1_1", "east": "2_0", "west": "0_0"},
        "tiles": tiles,
        "enemies": [
            {"enemy_id": "goblin_01", "tile_x": 8, "tile_y": 10, "heading": "west"},
            {"enemy_id": "goblin_01", "tile_x": 10, "tile_y": 12, "heading": "south"},
            {"enemy_id": "wolf_01", "tile_x": 24, "tile_y": 6, "heading": "north"},
            {"enemy_id": "wolf_01", "tile_x": 26, "tile_y": 8, "heading": "east"}
        ]
    }

def generate_chunk_0_1():
    """Darkwood Forest — dense forest with spiders and bandits."""
    tiles = []
    for y in range(CHUNK_SIZE):
        for x in range(CHUNK_SIZE):
            ground = "forest_floor_01"
            detail = ""
            obj = ""
            roof = ""
            collision = 0
            light = 0.7
            trigger_type = "none"
            trigger_data = {}

            # Dense tree coverage
            if (x + y * 2) % 5 == 0 and not (12 <= x <= 20 and 12 <= y <= 20):
                obj = "tree_dark_01"
                collision = 15

            # Clearing in center
            if 14 <= x <= 18 and 14 <= y <= 18:
                ground = "grass_dark_01"
                light = 0.85

            # Winding path
            if (13 <= x <= 15) and y < 14:
                ground = "dirt_path_01"
                obj = ""
                collision = 0
                light = 0.75

            # Mushroom patches
            if (x * 7 + y * 3) % 17 == 0 and obj == "":
                detail = "mushroom_01"

            # Spider webs
            if (x, y) in [(6, 20), (8, 22), (10, 24), (5, 25)]:
                detail = "spider_web_01"
                light = 0.5

            # Campfire in clearing (animated)
            if x == 16 and y == 16:
                obj = "campfire_01"
                light = 1.8

            tile = make_tile(x, y, ground, detail, obj, roof, collision, trigger_type, trigger_data, light)
            tiles.append(tile)

    # Set animated campfire
    for t in tiles:
        if t["x"] == 16 and t["y"] == 16:
            t["layers"]["object"]["frame_count"] = 6
            t["layers"]["object"]["frame_speed"] = 0.15

    return {
        "version": 1,
        "chunk_x": 0,
        "chunk_y": 1,
        "zone_id": "darkwood_forest",
        "neighbors": {"north": "0_0", "south": "0_2", "east": "1_1", "west": "-1_1"},
        "tiles": tiles,
        "enemies": [
            {"enemy_id": "spider_01", "tile_x": 7, "tile_y": 21, "heading": "south"},
            {"enemy_id": "spider_01", "tile_x": 9, "tile_y": 23, "heading": "west"},
            {"enemy_id": "bandit_01", "tile_x": 20, "tile_y": 16, "heading": "north"},
            {"enemy_id": "bandit_01", "tile_x": 22, "tile_y": 18, "heading": "west"}
        ]
    }

def generate_chunk_1_1():
    """Verdant Plains / Bone Crypt entrance — mixed terrain with dungeon entrance."""
    tiles = []
    for y in range(CHUNK_SIZE):
        for x in range(CHUNK_SIZE):
            ground = "grass_01"
            detail = ""
            obj = ""
            roof = ""
            collision = 0
            light = 1.0
            trigger_type = "none"
            trigger_data = {}

            # Rocky terrain in southeast (crypt area)
            if x > 20 and y > 20:
                ground = "stone_ground_01"
                light = 0.8

            # Crypt entrance
            if x == 26 and y == 26:
                obj = "crypt_entrance_01"
                trigger_type = "zone_transition"
                trigger_data = {"dest_x": 16, "dest_y": 16, "dest_chunk_x": 5, "dest_chunk_y": 5}

            # Crypt walls around entrance
            if 24 <= x <= 28 and 24 <= y <= 28 and not (x == 26 and y == 26):
                if x == 24 or x == 28 or y == 24 or y == 28:
                    obj = "crypt_wall_01"
                    collision = 15

            # Scattered boulders
            if (x, y) in [(4, 4), (12, 8), (8, 20), (18, 12), (28, 4)]:
                obj = "boulder_01"
                collision = 15

            # Dirt path connecting chunks
            if 14 <= x <= 17 and y < 10:
                ground = "dirt_path_01"

            if x < 10 and 14 <= y <= 17:
                ground = "dirt_path_01"

            # Tall grass
            if (x + y) % 6 == 0 and obj == "":
                detail = "tall_grass_01"

            tile = make_tile(x, y, ground, detail, obj, roof, collision, trigger_type, trigger_data, light)
            tiles.append(tile)

    return {
        "version": 1,
        "chunk_x": 1,
        "chunk_y": 1,
        "zone_id": "verdant_plains",
        "neighbors": {"north": "1_0", "south": "1_2", "east": "2_1", "west": "0_1"},
        "tiles": tiles,
        "enemies": [
            {"enemy_id": "skeleton_01", "tile_x": 24, "tile_y": 22, "heading": "south"},
            {"enemy_id": "skeleton_01", "tile_x": 26, "tile_y": 23, "heading": "west"},
            {"enemy_id": "goblin_01", "tile_x": 10, "tile_y": 10, "heading": "east"},
            {"enemy_id": "wolf_01", "tile_x": 6, "tile_y": 6, "heading": "south"}
        ]
    }

def main():
    chunks_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "chunks")
    os.makedirs(chunks_dir, exist_ok=True)

    chunks = [
        ("chunk_0_0.json", generate_chunk_0_0()),
        ("chunk_1_0.json", generate_chunk_1_0()),
        ("chunk_0_1.json", generate_chunk_0_1()),
        ("chunk_1_1.json", generate_chunk_1_1()),
    ]

    for filename, data in chunks:
        filepath = os.path.join(chunks_dir, filename)
        with open(filepath, "w") as f:
            json.dump(data, f, indent=2)
        print(f"Generated {filepath} ({len(data['tiles'])} tiles, {len(data.get('enemies', []))} enemies)")

if __name__ == "__main__":
    main()
