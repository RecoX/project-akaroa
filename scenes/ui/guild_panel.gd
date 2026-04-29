## Guild Panel — UI for guild management: creation form, news board,
## member list with roles, and alliance info.
##
## Starts hidden. Toggle via UI_Manager.
## Requirements: 20.1, 20.2, 20.4
extends PanelContainer


const TAG := "GuildPanel"


@onready var guild_name_input: LineEdit = $VBox/CreateSection/GuildNameInput
@onready var guild_tag_input: LineEdit = $VBox/CreateSection/GuildTagInput
@onready var create_button: Button = $VBox/CreateSection/CreateButton
@onready var create_section: VBoxContainer = $VBox/CreateSection
@onready var info_section: VBoxContainer = $VBox/InfoSection
@onready var guild_title_label: Label = $VBox/InfoSection/GuildTitleLabel
@onready var news_list: ItemList = $VBox/InfoSection/NewsBoard
@onready var member_list: ItemList = $VBox/InfoSection/MemberList
@onready var alliance_label: Label = $VBox/InfoSection/AllianceLabel


func _ready() -> void:
	visible = false
	create_button.pressed.connect(_on_create_pressed)
	_refresh_display()
	Log.info(TAG, "GuildPanel ready")


func _refresh_display() -> void:
	var guild_manager: Node = _get_guild_manager()
	if guild_manager == null:
		return

	var data: Dictionary = guild_manager.get_guild_data()
	if data.is_empty():
		create_section.visible = true
		info_section.visible = false
	else:
		create_section.visible = false
		info_section.visible = true
		guild_title_label.text = "%s <%s>" % [data.get("name", "?"), data.get("tag", "?")]

		# Populate news board.
		news_list.clear()
		var news: Array = guild_manager.get_news_board()
		for entry in news:
			news_list.add_item("[%s] %s" % [entry.get("author", "?"), entry.get("text", "")])

		# Populate member list.
		member_list.clear()
		var members: Array = guild_manager.get_members()
		for member in members:
			member_list.add_item("%s — %s (Lv %d)" % [
				member.get("name", "?"),
				member.get("role", "Member"),
				member.get("level", 1),
			])

		# Alliance info.
		var alliances: Array = data.get("alliances", [])
		if alliances.is_empty():
			alliance_label.text = "Alliances: None"
		else:
			alliance_label.text = "Alliances: %s" % ", ".join(alliances)


func _on_create_pressed() -> void:
	var guild_name := guild_name_input.text.strip_edges()
	var guild_tag := guild_tag_input.text.strip_edges()
	if guild_name.is_empty() or guild_tag.is_empty():
		Log.info(TAG, "Guild name or tag is empty")
		return

	var guild_manager: Node = _get_guild_manager()
	if guild_manager and guild_manager.has_method("create_guild"):
		guild_manager.create_guild(guild_name, guild_tag)
		_refresh_display()


func _get_guild_manager() -> Node:
	var gameplay := get_tree().current_scene
	if gameplay and gameplay.has_node("GuildManager"):
		return gameplay.get_node("GuildManager")
	# Try via parent chain.
	var parent := get_parent()
	while parent:
		var gm := parent.get_node_or_null("GuildManager")
		if gm:
			return gm
		parent = parent.get_parent()
	return null
