## Guild_Manager — manages guild data, creation, chat routing, and guild tag
## display on character names.
##
## Uses MockDataProvider for guild data. Routes guild chat through Chat_System.
## Lives as a child of GameplayScene.
## Requirements: 20.1, 20.2, 20.3, 20.4, 20.5
extends Node


const TAG := "GuildManager"


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when guild data changes (creation, update, etc.).
signal guild_data_changed(guild_data: Dictionary)

## Emitted when a guild member list is updated.
signal guild_members_updated(members: Array)

## Emitted when guild news is posted.
signal guild_news_posted(news_entry: Dictionary)


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Current guild data dictionary.
var _guild_data: Dictionary = {}

## Guild member list.
var _members: Array = []

## Guild news board entries.
var _news_board: Array = []


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	_load_guild_data()
	Log.info(TAG, "Guild_Manager ready")


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


## Creates a new guild with the given name and tag.
## Stores locally in MockDataProvider and updates player state.
func create_guild(guild_name: String, guild_tag: String) -> Dictionary:
	if guild_name.strip_edges().is_empty() or guild_tag.strip_edges().is_empty():
		Log.warning(TAG, "Cannot create guild — name or tag is empty")
		return {}

	var player_name: String = StateManager.player_data.get("name", "Player")
	_guild_data = {
		"id": guild_name.to_lower().replace(" ", "_"),
		"name": guild_name,
		"tag": guild_tag,
		"leader": player_name,
		"rank": "Guild Master",
		"members": [
			{"name": player_name, "role": "Guild Master", "level": StateManager.player_data.get("level", 1)},
		],
		"news": [
			{"author": "System", "text": "Guild '%s' has been founded!" % guild_name, "timestamp": Time.get_unix_time_from_system()},
		],
		"alliances": [],
	}

	_members = _guild_data.get("members", [])
	_news_board = _guild_data.get("news", [])

	# Update player state.
	StateManager.player_guild = _guild_data
	StateManager.player_data["guild_tag"] = guild_tag

	guild_data_changed.emit(_guild_data)
	Log.info(TAG, "Guild '%s' <%s> created by %s" % [guild_name, guild_tag, player_name])
	return _guild_data


## Returns the current guild data dictionary.
func get_guild_data() -> Dictionary:
	return _guild_data


## Returns the guild member list.
func get_members() -> Array:
	return _members


## Returns the guild news board entries.
func get_news_board() -> Array:
	return _news_board


## Sends a message to the guild chat channel via Chat_System.
func send_guild_chat(message: String) -> void:
	if _guild_data.is_empty():
		Log.info(TAG, "Not in a guild — cannot send guild chat")
		return

	var chat_system: Node = get_parent().get_node_or_null("ChatSystem")
	if chat_system and chat_system.has_method("send_message"):
		chat_system.send_message("/guild " + message)
	else:
		Log.warning(TAG, "ChatSystem not found — cannot route guild chat")


## Posts a news entry to the guild news board.
func post_news(text: String) -> void:
	if _guild_data.is_empty():
		Log.info(TAG, "Not in a guild — cannot post news")
		return

	var entry := {
		"author": StateManager.player_data.get("name", "Player"),
		"text": text,
		"timestamp": Time.get_unix_time_from_system(),
	}
	_news_board.append(entry)
	guild_news_posted.emit(entry)
	Log.info(TAG, "Guild news posted: %s" % text.left(40))


## Returns the guild tag string for display on character names.
func get_guild_tag() -> String:
	return _guild_data.get("tag", "")


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------


## Loads guild data from MockDataProvider and player state.
func _load_guild_data() -> void:
	# Check player state first.
	if not StateManager.player_guild.is_empty():
		_guild_data = StateManager.player_guild
	else:
		_guild_data = MockDataProvider.get_guild_data()

	if not _guild_data.is_empty():
		_members = _guild_data.get("members", [])
		_news_board = _guild_data.get("news", [])
		Log.info(TAG, "Loaded guild data: '%s'" % _guild_data.get("name", "?"))
	else:
		Log.info(TAG, "No guild data loaded — player is guildless")
