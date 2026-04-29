## Network_Client — Scaffolding Only.
##
## Defines the interface that game systems bind to. All methods are stubs with
## TODO placeholders. Mock mode emits fake signals so game systems can be
## developed and tested locally without a live server connection.
##
## Usage:
##   NetworkClient.send_login("account", "password")
##   NetworkClient.connected.connect(_on_connected)
extends Node


## All planned client-to-server and server-to-client message types.
enum MessageType {
	# Client -> Server
	MSG_LOGIN,
	MSG_MOVE,
	MSG_ATTACK,
	MSG_CAST_SPELL,
	MSG_CHAT,
	MSG_TRADE_REQUEST,
	MSG_TRADE_CONFIRM,
	MSG_INTERACT_NPC,
	MSG_USE_ITEM,
	MSG_EQUIP_ITEM,
	MSG_DROP_ITEM,
	MSG_CRAFT,
	MSG_QUEST_ACCEPT,
	MSG_GUILD_CREATE,
	MSG_GUILD_CHAT,
	# Server -> Client
	MSG_MAP_DATA,
	MSG_INVENTORY_UPDATE,
	MSG_CHARACTER_UPDATE,
	MSG_COMBAT_EVENT,
	MSG_CHAT_MESSAGE,
	MSG_QUEST_UPDATE,
	MSG_TRADE_EVENT,
	MSG_ZONE_CHANGE,
	MSG_WEATHER_UPDATE,
	MSG_SKILL_UPDATE,
	MSG_LEVEL_UP,
}


# ---------------------------------------------------------------------------
# Signals — game systems connect to these
# ---------------------------------------------------------------------------

## Emitted when a connection to the server is established.
signal connected()

## Emitted when the connection to the server is lost.
signal disconnected()

## Emitted on successful login with the list of available characters.
signal login_success(character_list: Array)

## Emitted when login fails.
signal login_failed(reason: String)

## Emitted when map/chunk data is received from the server.
signal map_data_received(chunk_data: Dictionary)

## Emitted when a character update is received from the server.
signal character_update_received(char_data: Dictionary)

## Emitted when an inventory slot update is received from the server.
signal inventory_update_received(slot: int, item_data: Dictionary)

## Emitted when a combat event is received from the server.
signal combat_event_received(event_data: Dictionary)

## Emitted when a chat message is received from the server.
signal chat_message_received(channel: String, sender: String, message: String)

## Emitted when a quest update is received from the server.
signal quest_update_received(quest_data: Dictionary)

## Emitted when a trade event is received from the server.
signal trade_event_received(trade_data: Dictionary)


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

const _TAG := "NetworkClient"

## Always true for the demo client. When true, stub methods emit fake signals
## using data from Mock_Data_Provider instead of sending real packets.
var mock_mode: bool = true


# ---------------------------------------------------------------------------
# Stub methods — all log the call and do nothing (TODO: real networking)
# ---------------------------------------------------------------------------


## Sends a login request to the server.
## In mock mode, emits [signal login_success] with mock characters from
## [MockDataProvider] after a short deferred delay to simulate async behavior.
func send_login(account: String, _password: String) -> void:
	# TODO: Implement actual login packet
	_log_stub("send_login", {"account": account})
	if mock_mode:
		_emit_deferred_login.call_deferred()


## Sends a movement packet for the given heading.
## No mock emit needed — movement is handled locally by the Tile_Engine.
func send_move(heading: int) -> void:
	# TODO: Implement actual move packet
	_log_stub("send_move", {"heading": heading})


## Sends an attack packet targeting [param target_id].
## In mock mode, emits [signal combat_event_received] with mock melee damage data.
func send_attack(target_id: String) -> void:
	# TODO: Implement actual attack packet
	_log_stub("send_attack", {"target_id": target_id})
	if mock_mode:
		_emit_deferred_combat_event.call_deferred({
			"type": "melee",
			"attacker_id": "player",
			"target_id": target_id,
			"damage": randi_range(5, 25),
			"is_critical": randf() < 0.15,
		})


## Sends a spell cast packet.
## In mock mode, emits [signal combat_event_received] with mock spell damage data.
func send_cast_spell(spell_id: String, target_id: String) -> void:
	# TODO: Implement actual cast spell packet
	_log_stub("send_cast_spell", {"spell_id": spell_id, "target_id": target_id})
	if mock_mode:
		var spell_data: Dictionary = MockDataProvider.get_spell(spell_id)
		var damage: int = spell_data.get("base_damage", randi_range(10, 40))
		_emit_deferred_combat_event.call_deferred({
			"type": "spell",
			"attacker_id": "player",
			"target_id": target_id,
			"spell_id": spell_id,
			"damage": damage,
			"is_critical": randf() < 0.1,
		})


## Sends a chat message packet.
## In mock mode, emits [signal chat_message_received] echoing the message back.
func send_chat(channel: String, message: String) -> void:
	# TODO: Implement actual chat packet
	_log_stub("send_chat", {"channel": channel, "message": message})
	if mock_mode:
		_emit_deferred_chat.call_deferred(channel, "Player", message)


## Sends a trade request to [param target_id].
## In mock mode, emits [signal trade_event_received] with mock trade open data.
func send_trade_request(target_id: String) -> void:
	# TODO: Implement actual trade request packet
	_log_stub("send_trade_request", {"target_id": target_id})
	if mock_mode:
		_emit_deferred_trade_event.call_deferred({
			"type": "trade_open",
			"partner_id": target_id,
			"partner_name": "MockTrader",
		})


## Sends a trade confirmation packet.
func send_trade_confirm() -> void:
	# TODO: Implement actual trade confirm packet
	_log_stub("send_trade_confirm", {})


## Sends an NPC interaction packet.
## No mock emit needed — NPC interaction is handled locally by State_Manager.
func send_interact_npc(npc_id: String) -> void:
	# TODO: Implement actual NPC interaction packet
	_log_stub("send_interact_npc", {"npc_id": npc_id})


## Sends a use item packet for the given inventory slot.
## In mock mode, emits [signal inventory_update_received] with mock data.
func send_use_item(slot_index: int) -> void:
	# TODO: Implement actual use item packet
	_log_stub("send_use_item", {"slot_index": slot_index})
	if mock_mode:
		_emit_deferred_inventory_update.call_deferred(slot_index, {
			"action": "use",
			"slot_index": slot_index,
			"result": "consumed",
		})


## Sends an equip item packet for the given inventory slot.
## In mock mode, emits [signal inventory_update_received] with mock data.
func send_equip_item(slot_index: int) -> void:
	# TODO: Implement actual equip item packet
	_log_stub("send_equip_item", {"slot_index": slot_index})
	if mock_mode:
		_emit_deferred_inventory_update.call_deferred(slot_index, {
			"action": "equip",
			"slot_index": slot_index,
			"result": "equipped",
		})


## Sends a drop item packet for the given inventory slot.
func send_drop_item(slot_index: int) -> void:
	# TODO: Implement actual drop item packet
	_log_stub("send_drop_item", {"slot_index": slot_index})


## Sends a craft request packet for the given recipe.
func send_craft(recipe_id: String) -> void:
	# TODO: Implement actual craft packet
	_log_stub("send_craft", {"recipe_id": recipe_id})


## Sends a quest accept packet.
## In mock mode, emits [signal quest_update_received] with mock quest data.
func send_quest_accept(quest_id: String) -> void:
	# TODO: Implement actual quest accept packet
	_log_stub("send_quest_accept", {"quest_id": quest_id})
	if mock_mode:
		var quest_data: Dictionary = MockDataProvider.get_quest(quest_id)
		if quest_data.is_empty():
			quest_data = {"id": quest_id, "status": "accepted"}
		else:
			quest_data["status"] = "accepted"
		_emit_deferred_quest_update.call_deferred(quest_data)


## Sends a guild creation packet.
func send_guild_create(guild_name: String, description: String) -> void:
	# TODO: Implement actual guild create packet
	_log_stub("send_guild_create", {"name": guild_name, "description": description})


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


## Logs a stub method call using the structured Logger utility.
func _log_stub(method_name: String, params: Dictionary) -> void:
	Log.info(_TAG, "STUB %s called with: %s" % [method_name, str(params)])


# ---------------------------------------------------------------------------
# Deferred mock emission helpers — simulate async server responses
# ---------------------------------------------------------------------------


## Deferred helper for login_success emission with mock characters.
func _emit_deferred_login() -> void:
	var characters: Array = MockDataProvider.get_mock_characters()
	Log.debug(_TAG, "Mock login_success emitted with %d characters" % characters.size())
	login_success.emit(characters)


## Deferred helper for combat_event_received emission.
func _emit_deferred_combat_event(event_data: Dictionary) -> void:
	Log.debug(_TAG, "Mock combat_event_received emitted: %s" % str(event_data))
	combat_event_received.emit(event_data)


## Deferred helper for chat_message_received emission.
func _emit_deferred_chat(channel: String, sender: String, message: String) -> void:
	Log.debug(_TAG, "Mock chat_message_received emitted: [%s] %s: %s" % [channel, sender, message])
	chat_message_received.emit(channel, sender, message)


## Deferred helper for trade_event_received emission.
func _emit_deferred_trade_event(trade_data: Dictionary) -> void:
	Log.debug(_TAG, "Mock trade_event_received emitted: %s" % str(trade_data))
	trade_event_received.emit(trade_data)


## Deferred helper for inventory_update_received emission.
func _emit_deferred_inventory_update(slot: int, item_data: Dictionary) -> void:
	Log.debug(_TAG, "Mock inventory_update_received emitted: slot=%d data=%s" % [slot, str(item_data)])
	inventory_update_received.emit(slot, item_data)


## Deferred helper for quest_update_received emission.
func _emit_deferred_quest_update(quest_data: Dictionary) -> void:
	Log.debug(_TAG, "Mock quest_update_received emitted: %s" % str(quest_data))
	quest_update_received.emit(quest_data)
