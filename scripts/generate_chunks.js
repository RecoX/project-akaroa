const fs = require('fs');
const path = require('path');

const CHUNK_SIZE = 32;

function makeTile(x, y, ground, detail, obj, roof, collision, triggerType, triggerData, light, elevation) {
  return {
    x, y,
    layers: {
      ground: { graphic_id: ground || "grass_01", frame_count: 1, frame_speed: 0.0 },
      detail: { graphic_id: detail || "", frame_count: 1, frame_speed: 0.0 },
      object: { graphic_id: obj || "", frame_count: 1, frame_speed: 0.0 },
      roof: { graphic_id: roof || "", frame_count: 1, frame_speed: 0.0 }
    },
    collision: collision || 0,
    trigger: { type: triggerType || "none", data: triggerData || {} },
    light: light != null ? light : 1.0,
    elevation: elevation || 0
  };
}

function genChunk00() {
  const tiles = [];
  for (let y = 0; y < CHUNK_SIZE; y++) {
    for (let x = 0; x < CHUNK_SIZE; x++) {
      let ground = "grass_01", detail = "", obj = "", roof = "";
      let collision = 0, triggerType = "none", triggerData = {}, light = 1.0;

      if (x >= 8 && x <= 24 && y >= 4 && y <= 24) ground = "cobblestone_01";

      // Blacksmith (12-18, 8-12)
      if (x >= 12 && x <= 18 && y >= 8 && y <= 12) {
        if (x === 12 || x === 18 || y === 8 || y === 12) {
          obj = "stone_wall_01"; collision = 15;
          if (x === 15 && y === 12) { obj = "door_01"; collision = 0; }
        } else { ground = "wood_floor_01"; roof = "roof_tile_01"; light = 0.8; }
      }
      // Healer (18-24, 10-14)
      if (x >= 18 && x <= 24 && y >= 10 && y <= 14) {
        if (x === 18 || x === 24 || y === 10 || y === 14) {
          obj = "stone_wall_01"; collision = 15;
          if (x === 21 && y === 14) { obj = "door_01"; collision = 0; }
        } else { ground = "wood_floor_01"; roof = "roof_tile_02"; light = 0.9; }
      }
      // Bank (16-22, 4-8)
      if (x >= 16 && x <= 22 && y >= 4 && y <= 8) {
        if (x === 16 || x === 22 || y === 4 || y === 8) {
          obj = "stone_wall_02"; collision = 15;
          if (x === 19 && y === 8) { obj = "door_02"; collision = 0; }
        } else { ground = "marble_floor_01"; roof = "roof_tile_03"; light = 0.85; }
      }
      // Fountain (15-17, 15-17)
      if (x >= 15 && x <= 17 && y >= 15 && y <= 17) {
        if (x === 16 && y === 16) { obj = "fountain_01"; detail = "water_splash"; collision = 15; }
        else if ((x === 15 || x === 17) && (y === 15 || y === 17)) { obj = "fountain_edge"; collision = 15; }
      }
      // Trees along edges
      if ((x < 3 || x > 28) && y % 3 === 0 && obj === "") { obj = "tree_oak_01"; collision = 15; }
      if ((y < 2 || y > 29) && x % 4 === 0 && obj === "") { obj = "tree_pine_01"; collision = 15; }
      // Torches
      const torches = [[10,8],[10,20],[22,8],[22,20],[16,14],[16,18]];
      if (torches.some(t => t[0]===x && t[1]===y)) { detail = "torch_01"; light = 1.5; }
      // Zone transition east
      if (x === 31 && y >= 12 && y <= 20) {
        triggerType = "zone_transition";
        triggerData = { dest_x: 0, dest_y: y, dest_chunk_x: 1, dest_chunk_y: 0 };
      }

      tiles.push(makeTile(x, y, ground, detail, obj, roof, collision, triggerType, triggerData, light));
    }
  }
  // Animated fountain
  const ft = tiles.find(t => t.x === 16 && t.y === 16);
  if (ft) { ft.layers.object.frame_count = 4; ft.layers.object.frame_speed = 0.3; }

  return {
    version: 1, chunk_x: 0, chunk_y: 0, zone_id: "akaroa_town",
    neighbors: { north: "0_-1", south: "0_1", east: "1_0", west: "-1_0" },
    tiles, enemies: []
  };
}

function genChunk10() {
  const tiles = [];
  for (let y = 0; y < CHUNK_SIZE; y++) {
    for (let x = 0; x < CHUNK_SIZE; x++) {
      let ground = "grass_01", detail = "", obj = "", roof = "";
      let collision = 0, triggerType = "none", triggerData = {}, light = 1.0;

      if (x >= 14 && x <= 17) ground = "dirt_path_01";
      const rocks = [[5,8],[22,3],[28,15],[10,25],[3,18]];
      if (rocks.some(r => r[0]===x && r[1]===y)) { obj = "rock_01"; collision = 15; }
      const trees = [[2,2],[7,12],[25,7],[30,22],[12,28],[20,20]];
      if (trees.some(t => t[0]===x && t[1]===y)) { obj = "tree_oak_01"; collision = 15; }
      if ((x + y) % 7 === 0 && !obj) detail = "tall_grass_01";
      if ((x * 3 + y * 5) % 13 === 0 && !obj && !detail) detail = "wildflower_01";
      if (x === 0 && y >= 12 && y <= 20) {
        triggerType = "zone_transition";
        triggerData = { dest_x: 31, dest_y: y, dest_chunk_x: 0, dest_chunk_y: 0 };
      }
      tiles.push(makeTile(x, y, ground, detail, obj, roof, collision, triggerType, triggerData, light));
    }
  }
  return {
    version: 1, chunk_x: 1, chunk_y: 0, zone_id: "verdant_plains",
    neighbors: { north: "1_-1", south: "1_1", east: "2_0", west: "0_0" },
    tiles,
    enemies: [
      { enemy_id: "goblin_01", tile_x: 8, tile_y: 10, heading: "west" },
      { enemy_id: "goblin_01", tile_x: 10, tile_y: 12, heading: "south" },
      { enemy_id: "wolf_01", tile_x: 24, tile_y: 6, heading: "north" },
      { enemy_id: "wolf_01", tile_x: 26, tile_y: 8, heading: "east" }
    ]
  };
}

function genChunk01() {
  const tiles = [];
  for (let y = 0; y < CHUNK_SIZE; y++) {
    for (let x = 0; x < CHUNK_SIZE; x++) {
      let ground = "forest_floor_01", detail = "", obj = "", roof = "";
      let collision = 0, triggerType = "none", triggerData = {}, light = 0.7;

      if ((x + y * 2) % 5 === 0 && !(x >= 12 && x <= 20 && y >= 12 && y <= 20)) {
        obj = "tree_dark_01"; collision = 15;
      }
      if (x >= 14 && x <= 18 && y >= 14 && y <= 18) { ground = "grass_dark_01"; light = 0.85; }
      if (x >= 13 && x <= 15 && y < 14) { ground = "dirt_path_01"; obj = ""; collision = 0; light = 0.75; }
      if ((x * 7 + y * 3) % 17 === 0 && !obj) detail = "mushroom_01";
      const webs = [[6,20],[8,22],[10,24],[5,25]];
      if (webs.some(w => w[0]===x && w[1]===y)) { detail = "spider_web_01"; light = 0.5; }
      if (x === 16 && y === 16) { obj = "campfire_01"; light = 1.8; }

      tiles.push(makeTile(x, y, ground, detail, obj, roof, collision, triggerType, triggerData, light));
    }
  }
  const cf = tiles.find(t => t.x === 16 && t.y === 16);
  if (cf) { cf.layers.object.frame_count = 6; cf.layers.object.frame_speed = 0.15; }

  return {
    version: 1, chunk_x: 0, chunk_y: 1, zone_id: "darkwood_forest",
    neighbors: { north: "0_0", south: "0_2", east: "1_1", west: "-1_1" },
    tiles,
    enemies: [
      { enemy_id: "spider_01", tile_x: 7, tile_y: 21, heading: "south" },
      { enemy_id: "spider_01", tile_x: 9, tile_y: 23, heading: "west" },
      { enemy_id: "bandit_01", tile_x: 20, tile_y: 16, heading: "north" },
      { enemy_id: "bandit_01", tile_x: 22, tile_y: 18, heading: "west" }
    ]
  };
}

function genChunk11() {
  const tiles = [];
  for (let y = 0; y < CHUNK_SIZE; y++) {
    for (let x = 0; x < CHUNK_SIZE; x++) {
      let ground = "grass_01", detail = "", obj = "", roof = "";
      let collision = 0, triggerType = "none", triggerData = {}, light = 1.0;

      if (x > 20 && y > 20) { ground = "stone_ground_01"; light = 0.8; }
      if (x === 26 && y === 26) {
        obj = "crypt_entrance_01";
        triggerType = "zone_transition";
        triggerData = { dest_x: 16, dest_y: 16, dest_chunk_x: 5, dest_chunk_y: 5 };
      }
      if (x >= 24 && x <= 28 && y >= 24 && y <= 28 && !(x === 26 && y === 26)) {
        if (x === 24 || x === 28 || y === 24 || y === 28) { obj = "crypt_wall_01"; collision = 15; }
      }
      const boulders = [[4,4],[12,8],[8,20],[18,12],[28,4]];
      if (boulders.some(b => b[0]===x && b[1]===y)) { obj = "boulder_01"; collision = 15; }
      if (x >= 14 && x <= 17 && y < 10) ground = "dirt_path_01";
      if (x < 10 && y >= 14 && y <= 17) ground = "dirt_path_01";
      if ((x + y) % 6 === 0 && !obj) detail = "tall_grass_01";

      tiles.push(makeTile(x, y, ground, detail, obj, roof, collision, triggerType, triggerData, light));
    }
  }
  return {
    version: 1, chunk_x: 1, chunk_y: 1, zone_id: "verdant_plains",
    neighbors: { north: "1_0", south: "1_2", east: "2_1", west: "0_1" },
    tiles,
    enemies: [
      { enemy_id: "skeleton_01", tile_x: 24, tile_y: 22, heading: "south" },
      { enemy_id: "skeleton_01", tile_x: 26, tile_y: 23, heading: "west" },
      { enemy_id: "goblin_01", tile_x: 10, tile_y: 10, heading: "east" },
      { enemy_id: "wolf_01", tile_x: 6, tile_y: 6, heading: "south" }
    ]
  };
}

const chunksDir = path.join(__dirname, '..', 'data', 'chunks');
fs.mkdirSync(chunksDir, { recursive: true });

const chunks = [
  ['chunk_0_0.json', genChunk00()],
  ['chunk_1_0.json', genChunk10()],
  ['chunk_0_1.json', genChunk01()],
  ['chunk_1_1.json', genChunk11()],
];

for (const [filename, data] of chunks) {
  const filepath = path.join(chunksDir, filename);
  fs.writeFileSync(filepath, JSON.stringify(data, null, 2));
  console.log(`Generated ${filename} (${data.tiles.length} tiles, ${data.enemies.length} enemies)`);
}
