## Chat_System — handles all chat channels with local echo, /command parsing,
## and chat bubble requests.
##
## Supports LOCAL, GLOBAL, GUILD, PRIVATE, and FACTION channels. All messages
## are processed locally (no server). Commands like /guild, /global, /local,
## /whisper, and /faction switch channels or send targeted messages.
##
## Lives as a child of GameplayScene.
## Requirements: 13.1, 13.2, 13.3, 13.4, 13.6
extends Node


const TAG := "ChatSystem"


## Chat channel types.
enum Channel { LOCAL, GLOBAL, GUILD, PRIVATE, FACTION }


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when a message is processed and ready for display.
## [param channel] is the Channel enum value.
## [param sender] is the display name of the sender.
## [param text] is the message content.
## [param color] is the channel color for rendering.
signal message_processed(channel: int, sender: String, text: String, color: Color)

## Emitted when a local chat message should appear as a bubble above a character.
signal bubble_requested(char_id: String, text: String, duration: float)


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## The currently active chat channel.
var _active_channel: Channel = Channel.LOCAL

## Color mapping for each channel.
var _channel_colors: Dictionary = {
	Channel.LOCAL: Color.WHITE,
	Channel.GLOBAL: Color.CYAN,
	Channel.GUILD: Color(0.3, 0.9, 0.3),  # green
	Channel.PRIVATE: Color(0.9, 0.3, 0.9),  # magenta
	Channel.FACTION: Color(0.9, 0.9, 0.3),  # yellow
}

## Human-readable channel names.
var _channel_names: Dictionary = {
	Channel.LOCAL: "Local",
	Channel.GLOBAL: "Global",
	Channel.GUILD: "Guild",
	Channel.PRIVATE: "Private",
	Channel.FACTION: "Faction",
}


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	Log.info(TAG, "Chat_System ready — active channel: %s" % _channel_names[_active_channel])


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


## Processes a raw text message from the player. Parses /commands or sends
## the message on the active channel.
func send_message(raw_text: String) -> void:
	if raw_text.strip_edges().is_empty():
		return

	if raw_text.begins_with("/"):
		_process_command(raw_text)
	else:
		var sender: String = StateManager.player_data.get("name", "Player")
		_echo_message(_active_channel, sender, raw_text)


## Returns the currently active channel.
func get_active_channel() -> Channel:
	return _active_channel


## Sets the active channel.
func set_active_channel(channel: Channel) -> void:
	_active_channel = channel
	Log.info(TAG, "Active channel set to %s" % _channel_names[channel])


## Returns the color for a given channel.
func get_channel_color(channel: Channel) -> Color:
	return _channel_colors.get(channel, Color.WHITE)


## Returns the display name for a given channel.
func get_channel_name(channel: Channel) -> String:
	return _channel_names.get(channel, "Unknown")


# ---------------------------------------------------------------------------
# Command processing
# ---------------------------------------------------------------------------


## Parses and processes /commands.
func _process_command(text: String) -> void:
	var parts := text.split(" ", true, 2)
	var cmd: String = parts[0].to_lower()
	var sender: String = StateManager.player_data.get("name", "Player")

	match cmd:
		"/guild", "/g":
			if parts.size() >= 2:
				# Send message to guild channel.
				_echo_message(Channel.GUILD, sender, parts[1])
			else:
				# Switch active channel to guild.
				_active_channel = Channel.GUILD
				_echo_system_message("Switched to Guild channel")

		"/global", "/gl":
			if parts.size() >= 2:
				_echo_message(Channel.GLOBAL, sender, parts[1])
			else:
				_active_channel = Channel.GLOBAL
				_echo_system_message("Switched to Global channel")

		"/local", "/l":
			if parts.size() >= 2:
				_echo_message(Channel.LOCAL, sender, parts[1])
			else:
				_active_channel = Channel.LOCAL
				_echo_system_message("Switched to Local channel")

		"/whisper", "/w", "/tell":
			if parts.size() >= 3:
				var target_name: String = parts[1]
				var whisper_text: String = parts[2]
				_echo_whisper(sender, target_name, whisper_text)
			else:
				_echo_system_message("Usage: /whisper <name> <message>")

		"/faction", "/f":
			if parts.size() >= 2:
				_echo_message(Channel.FACTION, sender, parts[1])
			else:
				_active_channel = Channel.FACTION
				_echo_system_message("Switched to Faction channel")

		"/help":
			_echo_system_message("Commands: /guild, /global, /local, /whisper <name> <msg>, /faction, /help")

		_:
			_echo_system_message("Unknown command: %s — type /help for commands" % cmd)


# ---------------------------------------------------------------------------
# Message echoing
# ---------------------------------------------------------------------------


## Echoes a message locally on the given channel. Emits message_processed
## and bubble_requested (for LOCAL channel).
func _echo_message(channel: Channel, sender: String, text: String) -> void:
	var color: Color = _channel_colors.get(channel, Color.WHITE)

	# Emit for chat console display.
	message_processed.emit(channel, sender, text, color)

	# Also emit through StateManager for broader consumption.
	StateManager.chat_message.emit(_channel_names[channel], sender, text, color)

	# For LOCAL channel, request a chat bubble above the player character.
	if channel == Channel.LOCAL:
		var duration: float = clampf(text.length() * 0.08, 2.0, 10.0)
		var char_id: String = StateManager.player_data.get("id", "player")
		bubble_requested.emit(char_id, text, duration)
		StateManager.chat_bubble.emit(char_id, text, duration)

	Log.debug(TAG, "[%s] %s: %s" % [_channel_names[channel], sender, text])


## Echoes a whisper message (private channel).
func _echo_whisper(sender: String, target_name: String, text: String) -> void:
	var color: Color = _channel_colors.get(Channel.PRIVATE, Color.MAGENTA)

	# Show outgoing whisper.
	var outgoing_text := "To %s: %s" % [target_name, text]
	message_processed.emit(Channel.PRIVATE, sender, outgoing_text, color)

	# Simulate a mock reply after a short delay (for demo purposes).
	var reply_text := "Thanks for the message!"
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(func():
		var incoming_text := "%s whispers: %s" % [target_name, reply_text]
		message_processed.emit(Channel.PRIVATE, target_name, incoming_text, color)
	)

	Log.debug(TAG, "[Whisper] %s -> %s: %s" % [sender, target_name, text])


## Echoes a system message (no sender, uses a neutral color).
func _echo_system_message(text: String) -> void:
	var system_color := Color(0.7, 0.7, 0.7)
	message_processed.emit(Channel.LOCAL, "System", text, system_color)
	Log.debug(TAG, "[System] %s" % text)
