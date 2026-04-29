## Minimap — top-down orthographic view with player marker, POI markers,
## zone label, coordinate label, and zoom controls.
##
## Uses a SubViewport with an orthographic Camera3D to render a top-down view.
## Follows the player position. Starts visible in the HUD corner.
## Requirements: 27.1, 27.2, 27.3, 27.4
extends PanelContainer


const TAG := "Minimap"
const TILE_SIZE: float = 32.0
const DEFAULT_ZOOM: float = 200.0
const MIN_ZOOM: float = 100.0
const MAX_ZOOM: float = 500.0
const ZOOM_STEP: float = 50.0

## POI type to color mapping.
const POI_COLORS: Dictionary = {
	"npc": Color(0.2, 0.8, 0.2),
	"shop": Color(0.9, 0.8, 0.2),
	"quest": Color(0.9, 0.5, 0.1),
	"zone_exit": Color(0.3, 0.5, 1.0),
	"safe_zone": Color(0.2, 0.9, 0.9),
	"enemy": Color(0.9, 0.2, 0.2),
	"bank": Color(0.8, 0.7, 0.2),
	"default": Color(0.7, 0.7, 0.7),
}


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _current_zoom: float = DEFAULT_ZOOM
var _poi_markers: Array = []


# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@onready var minimap_viewport: SubViewport = $VBox/MinimapViewport
@onready var minimap_camera: Camera3D = $VBox/MinimapViewport/MinimapCamera
@onready var player_marker: MeshInstance3D = $VBox/MinimapViewport/PlayerMarker
@onready var poi_container: Node3D = $VBox/MinimapViewport/POIContainer
@onready var minimap_texture: TextureRect = $VBox/MinimapTexture
@onready var zone_label: Label = $VBox/InfoBar/ZoneLabel
@onready var coordinate_label: Label = $VBox/InfoBar/CoordinateLabel
@onready var zoom_in_button: Button = $VBox/ZoomControls/ZoomInButton
@onready var zoom_out_button: Button = $VBox/ZoomControls/ZoomOutButton


func _ready() -> void:
	# Connect signals.
	StateManager.player_position_changed.connect(_on_player_position_changed)
	StateManager.zone_changed.connect(_on_zone_changed)
	zoom_in_button.pressed.connect(_on_zoom_in)
	zoom_out_button.pressed.connect(_on_zoom_out)

	# Setup camera.
	_setup_camera()

	# Bind viewport texture to the TextureRect.
	(func():
		minimap_texture.texture = minimap_viewport.get_texture()
	).call_deferred()

	Log.info(TAG, "Minimap ready")


func _setup_camera() -> void:
	minimap_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	minimap_camera.size = _current_zoom
	# Top-down view: looking straight down.
	minimap_camera.rotation_degrees = Vector3(-90, 0, 0)
	minimap_camera.position = Vector3(0, 100, 0)


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------


func _on_player_position_changed(tile_x: int, tile_y: int) -> void:
	var world_x: float = tile_x * TILE_SIZE + TILE_SIZE * 0.5
	var world_z: float = tile_y * TILE_SIZE + TILE_SIZE * 0.5

	# Move camera to follow player.
	minimap_camera.position.x = world_x
	minimap_camera.position.z = world_z

	# Move player marker.
	player_marker.position = Vector3(world_x, 5.0, world_z)

	# Update coordinate label.
	coordinate_label.text = "(%d, %d)" % [tile_x, tile_y]


func _on_zone_changed(zone_data: Dictionary) -> void:
	zone_label.text = zone_data.get("name", "Unknown")
	refresh_pois_from_chunks()


func _on_zoom_in() -> void:
	_current_zoom = maxf(MIN_ZOOM, _current_zoom - ZOOM_STEP)
	minimap_camera.size = _current_zoom
	Log.debug(TAG, "Minimap zoom: %.0f" % _current_zoom)


func _on_zoom_out() -> void:
	_current_zoom = minf(MAX_ZOOM, _current_zoom + ZOOM_STEP)
	minimap_camera.size = _current_zoom
	Log.debug(TAG, "Minimap zoom: %.0f" % _current_zoom)


# ---------------------------------------------------------------------------
# POI markers
# ---------------------------------------------------------------------------


## Refreshes POI markers from currently loaded chunk data.
func refresh_pois_from_chunks() -> void:
	# Clear existing POI markers.
	for marker in _poi_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_poi_markers.clear()

	# Get player chunk and scan nearby chunks for POIs.
	var px: int = StateManager.player_position.x
	var py: int = StateManager.player_position.y
	@warning_ignore("integer_division")
	var cx: int = px / 32
	@warning_ignore("integer_division")
	var cy: int = py / 32

	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var chunk: Dictionary = MockDataProvider.get_chunk(cx + dx, cy + dy)
			if chunk.is_empty():
				continue
			var pois: Array = chunk.get("pois", [])
			for poi in pois:
				_add_poi_marker(poi)

			# Also add enemies as POI markers.
			var enemies: Array = chunk.get("enemies", [])
			for enemy in enemies:
				var enemy_poi := {
					"type": "enemy",
					"x": enemy.get("position_x", 0),
					"y": enemy.get("position_y", 0),
					"name": enemy.get("name", "Enemy"),
				}
				_add_poi_marker(enemy_poi)


## Adds a single POI marker to the minimap.
func _add_poi_marker(poi: Dictionary) -> void:
	var poi_type: String = poi.get("type", "default")
	var poi_x: float = poi.get("x", 0) * TILE_SIZE + TILE_SIZE * 0.5
	var poi_z: float = poi.get("y", 0) * TILE_SIZE + TILE_SIZE * 0.5
	var color: Color = POI_COLORS.get(poi_type, POI_COLORS["default"])

	var marker := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 4.0
	sphere.height = 8.0
	marker.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	marker.material_override = mat

	marker.position = Vector3(poi_x, 3.0, poi_z)
	poi_container.add_child(marker)
	_poi_markers.append(marker)
