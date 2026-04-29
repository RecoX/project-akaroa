## Chat Console — scrollable chat panel with channel filtering, message input,
## and Enter-to-send functionality.
##
## Connects to Chat_System.message_processed to display incoming messages
## with channel-appropriate colors. The Chat_System node is a sibling in
## GameplayScene, accessed via the scene tree.
##
## Requirements: 13.5
extends Control


const TAG := "ChatConsole"

## Maximum number of messages to keep in the display buffer.
const MAX_MESSAGES: int = 200

## Channel filter names matching Chat_System.Channel enum order.
const CHANNEL_NAMES: Array = ["Local", "Global", "Guild", "Private", "Faction"]


# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@onready var message_display: RichTextLabel = $PanelContainer/VBoxContainer/MessageDisplay
@onready var input_field: LineEdit = $PanelContainer/VBoxContainer/InputContainer/MessageInput
@onready var filter_container: HBoxContainer = $PanelContainer/VBoxContainer/FilterBar


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Which channels are currently visible. Maps channel index -> bool.
var _channel_filters: Dictionary = {
	0: true,  # LOCAL
	1: true,  # GLOBAL
	2: true,  # GUILD
	3: true,  # PRIVATE
	4: true,  # FACTION
}

## Reference to the Chat_System node (resolved at runtime).
var _chat_system: Node = null

## Message history for filtering.
var _message_history: Array = []


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	# Configure the message display.
	message_display.bbcode_enabled = true
	message_display.scroll_following = true

	# Connect input field Enter key.
	input_field.text_submitted.connect(_on_message_submitted)

	# Set up channel filter buttons.
	_setup_filter_buttons()

	# Find and connect to Chat_System (deferred to ensure scene tree is ready).
	call_deferred("_connect_chat_system")

	Log.info(TAG, "Chat Console ready")


# ---------------------------------------------------------------------------
# Chat_System connection
# ---------------------------------------------------------------------------


## Finds the Chat_System node in the scene tree and connects to its signals.
func _connect_chat_system() -> void:
	# Chat_System is a sibling node in GameplayScene.
	# Navigate up through UILayer -> GameplayScene -> ChatSystem.
	var gameplay_scene: Node = _find_gameplay_scene()
	if gameplay_scene:
		_chat_system = gameplay_scene.get_node_or_null("ChatSystem")

	if _chat_system:
		if _chat_system.has_signal("message_processed"):
			_chat_system.message_processed.connect(_on_message_processed)
		Log.info(TAG, "Connected to Chat_System")
	else:
		Log.warning(TAG, "Chat_System not found — chat will not display messages")


## Walks up the tree to find the GameplayScene node.
func _find_gameplay_scene() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.name == "GameplayScene":
			return node
		# Also check if it has a ChatSystem child (in case name differs).
		if node.get_node_or_null("ChatSystem") != null:
			return node
		node = node.get_parent()
	return null


# ---------------------------------------------------------------------------
# Message display
# ---------------------------------------------------------------------------


## Handles incoming messages from Chat_System.
func _on_message_processed(channel: int, sender: String, text: String, color: Color) -> void:
	# Store in history.
	_message_history.append({
		"channel": channel,
		"sender": sender,
		"text": text,
		"color": color,
	})

	# Trim history if too large.
	while _message_history.size() > MAX_MESSAGES:
		_message_history.pop_front()

	# Display if channel filter allows it.
	if _channel_filters.get(channel, true):
		_append_message(sender, text, color)


## Appends a formatted message to the RichTextLabel.
func _append_message(sender: String, text: String, color: Color) -> void:
	var color_hex: String = color.to_html(false)
	var formatted: String = "[color=#%s]%s: %s[/color]" % [color_hex, sender, text]
	message_display.append_text(formatted + "\n")


# ---------------------------------------------------------------------------
# Input handling
# ---------------------------------------------------------------------------


## Called when the player presses Enter in the input field.
func _on_message_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		input_field.clear()
		return

	# Send through Chat_System.
	if _chat_system and _chat_system.has_method("send_message"):
		_chat_system.send_message(text)
	else:
		Log.warning(TAG, "Chat_System not available — message not sent")

	# Clear the input field.
	input_field.clear()

	# Keep focus on the input field for continuous chatting.
	input_field.grab_focus()


## Handles unhandled input to focus the chat input on Enter press.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		if not input_field.has_focus():
			input_field.grab_focus()
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Channel filtering
# ---------------------------------------------------------------------------


## Creates toggle buttons for each channel filter.
func _setup_filter_buttons() -> void:
	for i in range(CHANNEL_NAMES.size()):
		var button := Button.new()
		button.text = CHANNEL_NAMES[i]
		button.toggle_mode = true
		button.button_pressed = true
		button.custom_minimum_size = Vector2(60, 24)
		button.add_theme_font_size_override("font_size", 11)

		# Capture the channel index in the lambda.
		var channel_index: int = i
		button.toggled.connect(func(pressed: bool):
			_on_filter_toggled(channel_index, pressed)
		)

		filter_container.add_child(button)


## Handles a channel filter button toggle.
func _on_filter_toggled(channel_index: int, enabled: bool) -> void:
	_channel_filters[channel_index] = enabled
	_refresh_display()
	Log.debug(TAG, "Channel '%s' filter: %s" % [CHANNEL_NAMES[channel_index], str(enabled)])


## Rebuilds the message display based on current filters.
func _refresh_display() -> void:
	message_display.clear()
	for msg in _message_history:
		var channel: int = msg.get("channel", 0)
		if _channel_filters.get(channel, true):
			_append_message(msg["sender"], msg["text"], msg["color"])
