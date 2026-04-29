## Login screen — server selection, account/password fields, and connect button.
##
## On connect: calls NetworkClient.send_login() which in mock mode emits
## login_success and transitions to CHARACTER_SELECT.
## Requirements: 9.1, 9.5
extends Control


const TAG := "LoginScreen"

@onready var server_option: OptionButton = %ServerOption
@onready var account_input: LineEdit = %AccountInput
@onready var password_input: LineEdit = %PasswordInput
@onready var connect_button: Button = %ConnectButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	# Populate server list with mock server.
	server_option.clear()
	server_option.add_item("Local Mock Server", 0)

	# Set default account for convenience.
	account_input.text = "demo"
	password_input.text = ""

	# Wire button.
	connect_button.pressed.connect(_on_connect_pressed)

	# Wire network signals (TODO placeholders for future server integration).
	NetworkClient.login_success.connect(_on_login_success)
	NetworkClient.login_failed.connect(_on_login_failed)

	status_label.text = ""
	Log.info(TAG, "Login screen ready")


## Called when the player presses the Connect button.
func _on_connect_pressed() -> void:
	var account := account_input.text.strip_edges()
	if account == "":
		status_label.text = "Please enter an account name."
		return

	status_label.text = "Connecting..."
	connect_button.disabled = true
	Log.info(TAG, "Login attempt — account: %s" % account)
	NetworkClient.send_login(account, password_input.text)


## Signal hook: called on successful login. Transitions to character select.
## TODO: Future server integration — handle auth token, session data.
func _on_login_success(_character_list: Array) -> void:
	Log.info(TAG, "Login success — transitioning to CHARACTER_SELECT")
	status_label.text = "Login successful!"
	StateManager.transition_to(StateManager.AppState.CHARACTER_SELECT)


## Signal hook: called on login failure.
## TODO: Future server integration — display server error message.
func _on_login_failed(reason: String) -> void:
	Log.warning(TAG, "Login failed: %s" % reason)
	status_label.text = "Login failed: %s" % reason
	connect_button.disabled = false
