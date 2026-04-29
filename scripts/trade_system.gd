## Trade_System — manages NPC shop buy/sell and player-to-player trading.
##
## All transactions operate on local mock data through StateManager and
## MockDataProvider. Lives as a child of GameplayScene.
##
## Requirements: 14.3, 14.4, 15.1, 15.3, 15.4, 15.5
extends Node


const TAG := "TradeSystem"

## Maximum number of trade offer slots per player.
const TRADE_SLOTS := 6


# ---------------------------------------------------------------------------
# Trade session state
# ---------------------------------------------------------------------------

## Whether a P2P trade session is currently active.
var _trade_active: bool = false

## The partner's character data for the current trade.
var _trade_partner: Dictionary = {}

## Items the player has placed in the trade window. Array of item dicts.
var _player_offer: Array = []

## Items the partner has placed (mock). Array of item dicts.
var _partner_offer: Array = []

## Gold amounts offered.
var _player_gold_offer: int = 0
var _partner_gold_offer: int = 0

## Whether each side has confirmed.
var _player_confirmed: bool = false
var _partner_confirmed: bool = false


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


func _ready() -> void:
	_player_offer.resize(TRADE_SLOTS)
	_partner_offer.resize(TRADE_SLOTS)
	_clear_offers()
	Log.info(TAG, "Trade_System ready")


# ---------------------------------------------------------------------------
# NPC Shop — Buy / Sell
# ---------------------------------------------------------------------------


## Buys an item from an NPC shop. Deducts gold and adds item to inventory.
## Returns true on success.
func buy_from_npc(npc_id: String, item_id: String) -> bool:
	var npc_data: Dictionary = MockDataProvider.get_npc(npc_id)
	if npc_data.is_empty():
		Log.warning(TAG, "buy_from_npc: NPC '%s' not found" % npc_id)
		return false

	var item_data: Dictionary = MockDataProvider.get_item(item_id)
	if item_data.is_empty():
		Log.warning(TAG, "buy_from_npc: Item '%s' not found" % item_id)
		return false

	var price: int = item_data.get("value", 0)
	var current_gold: int = StateManager.player_data.get("gold", 0)

	if current_gold < price:
		Log.info(TAG, "Not enough gold to buy '%s' (need %d, have %d)" % [
			item_data.get("name", "?"), price, current_gold])
		return false

	# Find an empty inventory slot.
	var inv_manager: Node = _get_inventory_manager()
	if inv_manager == null:
		Log.error(TAG, "InventoryManager not found")
		return false

	var slot_index: int = inv_manager.add_item(item_data.duplicate())
	if slot_index < 0:
		Log.info(TAG, "Inventory full — cannot buy '%s'" % item_data.get("name", "?"))
		return false

	# Deduct gold.
	StateManager.player_data["gold"] = current_gold - price
	StateManager.player_gold_changed.emit(StateManager.player_data["gold"])

	Log.info(TAG, "Bought '%s' for %d gold from NPC '%s'" % [
		item_data.get("name", "?"), price, npc_data.get("name", "?")])
	return true


## Sells an item from the player's inventory to an NPC. Removes item, adds gold.
## Returns true on success.
func sell_to_npc(npc_id: String, slot_index: int) -> bool:
	var inv_manager: Node = _get_inventory_manager()
	if inv_manager == null:
		Log.error(TAG, "InventoryManager not found")
		return false

	var item: Dictionary = inv_manager.get_slot(slot_index)
	if item.is_empty():
		Log.info(TAG, "sell_to_npc: Slot %d is empty" % slot_index)
		return false

	# Sell price is half the item value.
	var sell_price: int = int(item.get("value", 0) * 0.5)

	# Remove item from inventory.
	inv_manager.drop_item(slot_index)

	# Add gold.
	var current_gold: int = StateManager.player_data.get("gold", 0)
	StateManager.player_data["gold"] = current_gold + sell_price
	StateManager.player_gold_changed.emit(StateManager.player_data["gold"])

	Log.info(TAG, "Sold '%s' for %d gold" % [item.get("name", "?"), sell_price])
	return true


# ---------------------------------------------------------------------------
# Player-to-Player Trade
# ---------------------------------------------------------------------------


## Opens a trade session with a partner (mock).
func open_trade(partner_id: String) -> void:
	if _trade_active:
		Log.info(TAG, "Trade already active — cancel first")
		return

	# Build mock partner data.
	_trade_partner = {"id": partner_id, "name": "Player_%s" % partner_id}
	_trade_active = true
	_clear_offers()

	StateManager.trade_opened.emit(_trade_partner)
	Log.info(TAG, "Trade opened with '%s'" % _trade_partner.get("name", "?"))


## Places an item from inventory into a trade offer slot.
func place_item(inventory_slot: int, trade_slot: int) -> void:
	if not _trade_active:
		Log.warning(TAG, "No active trade session")
		return
	if trade_slot < 0 or trade_slot >= TRADE_SLOTS:
		Log.warning(TAG, "Invalid trade slot: %d" % trade_slot)
		return

	var inv_manager: Node = _get_inventory_manager()
	if inv_manager == null:
		return

	var item: Dictionary = inv_manager.get_slot(inventory_slot)
	if item.is_empty():
		Log.info(TAG, "Inventory slot %d is empty" % inventory_slot)
		return

	_player_offer[trade_slot] = item.duplicate()
	_player_confirmed = false
	_partner_confirmed = false

	StateManager.trade_slot_updated.emit(true, trade_slot, _player_offer[trade_slot])
	Log.info(TAG, "Placed '%s' in trade slot %d" % [item.get("name", "?"), trade_slot])


## Sets the gold amount the player offers in the trade.
func set_gold_offer(amount: int) -> void:
	if not _trade_active:
		return
	var current_gold: int = StateManager.player_data.get("gold", 0)
	_player_gold_offer = clampi(amount, 0, current_gold)
	_player_confirmed = false
	_partner_confirmed = false
	Log.info(TAG, "Gold offer set to %d" % _player_gold_offer)


## Confirms the player's side of the trade. When both sides confirm, execute.
func confirm_trade() -> void:
	if not _trade_active:
		return

	_player_confirmed = true
	Log.info(TAG, "Player confirmed trade")

	# In mock mode, auto-confirm partner after a short delay.
	_partner_confirmed = true
	Log.info(TAG, "Partner confirmed trade (mock)")

	if _player_confirmed and _partner_confirmed:
		_execute_trade()


## Cancels the current trade session.
func cancel_trade() -> void:
	if not _trade_active:
		return

	_trade_active = false
	_clear_offers()
	StateManager.trade_closed.emit()
	Log.info(TAG, "Trade cancelled")


## Returns whether a trade is currently active.
func is_trade_active() -> bool:
	return _trade_active


## Returns the current player offer array.
func get_player_offer() -> Array:
	return _player_offer


## Returns the current partner offer array.
func get_partner_offer() -> Array:
	return _partner_offer


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------


## Executes the trade — swap items and gold between player and partner (mock).
func _execute_trade() -> void:
	var inv_manager: Node = _get_inventory_manager()
	if inv_manager == null:
		cancel_trade()
		return

	# Remove offered items from player inventory.
	for i in range(TRADE_SLOTS):
		var offered: Dictionary = _player_offer[i]
		if offered.is_empty():
			continue
		# Find and remove the item from inventory.
		for slot_idx in range(inv_manager.SLOT_COUNT):
			var inv_item: Dictionary = inv_manager.get_slot(slot_idx)
			if not inv_item.is_empty() and inv_item.get("id", "") == offered.get("id", ""):
				inv_manager.drop_item(slot_idx)
				break

	# Add partner's offered items to player inventory (mock items).
	for i in range(TRADE_SLOTS):
		var received: Dictionary = _partner_offer[i]
		if received.is_empty():
			continue
		inv_manager.add_item(received.duplicate())

	# Gold exchange.
	var current_gold: int = StateManager.player_data.get("gold", 0)
	current_gold = current_gold - _player_gold_offer + _partner_gold_offer
	StateManager.player_data["gold"] = maxi(0, current_gold)
	StateManager.player_gold_changed.emit(StateManager.player_data["gold"])

	Log.info(TAG, "Trade executed successfully")

	_trade_active = false
	_clear_offers()
	StateManager.trade_closed.emit()


## Resets all offer slots and confirmation flags.
func _clear_offers() -> void:
	for i in range(TRADE_SLOTS):
		_player_offer[i] = {}
		_partner_offer[i] = {}
	_player_gold_offer = 0
	_partner_gold_offer = 0
	_player_confirmed = false
	_partner_confirmed = false


## Finds the InventoryManager node in the scene tree.
func _get_inventory_manager() -> Node:
	var parent := get_parent()
	if parent and parent.has_node("Inventory_Manager"):
		return parent.get_node("Inventory_Manager")
	# Fallback: search siblings.
	if parent:
		for child in parent.get_children():
			if child.name == "Inventory_Manager":
				return child
	Log.warning(TAG, "Could not find Inventory_Manager node")
	return null
