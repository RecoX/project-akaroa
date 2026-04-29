## Structured logging utility with configurable log levels and per-subsystem tags.
##
## This is an autoload singleton (registered as "Logger" in project.godot).
## Other scripts access it via the autoload name: Log.info("Tag", "msg")
##
## In Godot 4.6, autoload singletons are accessible by name in all scripts
## that load AFTER the autoload is registered. Since Logger is the first
## autoload, all other scripts can use it.
extends Node


## Log level severity values. Messages below the minimum level are suppressed.
enum Level {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3,
}


## The minimum log level. Messages with a level below this are ignored.
var min_level: int = Level.INFO


## Human-readable names for each log level.
const _LEVEL_NAMES: Dictionary = {
	0: "DEBUG",
	1: "INFO",
	2: "WARNING",
	3: "ERROR",
}


## Sets the minimum log level.
func set_log_level(level: int) -> void:
	min_level = level


## Returns the current minimum log level.
func get_log_level() -> int:
	return min_level


## Logs a debug message.
func debug(tag: String, message: String) -> void:
	_log(Level.DEBUG, tag, message)


## Logs an informational message.
func info(tag: String, message: String) -> void:
	_log(Level.INFO, tag, message)


## Logs a warning message.
func warning(tag: String, message: String) -> void:
	_log(Level.WARNING, tag, message)


## Logs an error message.
func error(tag: String, message: String) -> void:
	_log(Level.ERROR, tag, message)


## Internal log dispatch.
func _log(level: int, tag: String, message: String) -> void:
	if level < min_level:
		return

	var formatted := "[%s] [%s] %s" % [_LEVEL_NAMES.get(level, "?"), tag, message]

	if level >= Level.ERROR:
		push_error(formatted)
	elif level >= Level.WARNING:
		push_warning(formatted)
	else:
		print(formatted)
