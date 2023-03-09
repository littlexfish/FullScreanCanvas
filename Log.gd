extends Node

enum {
	T_DEBUG = 0,
	T_INFO = 1,
	T_WARNING = 2,
	T_ERROR = 3
}

var logType = T_DEBUG if OS.is_debug_build() else T_INFO

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _log(type: int, title, content):
	if type < logType:
		return
	var st = str(title)
	var sc = str(content)
	var time = Time.get_time_string_from_system()
	var color := ''
	match type:
		T_DEBUG:
			color = '[color=blue]'
		T_INFO:
			color = '[color=white]'
		T_WARNING:
			color = '[color=orange]'
		T_ERROR:
			color = '[color=red]'
	print_rich('%s[%s]%s: %s[/color]' % [color, time, st, sc])

func d(title, content):
	_log(T_DEBUG, title, content)

func i(title, content):
	_log(T_INFO, title, content)

func w(title, content):
	_log(T_WARNING, title, content)

func e(title, content):
	_log(T_ERROR, title, content)




