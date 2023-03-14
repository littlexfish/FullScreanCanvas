extends Window

signal l_button_pressed(window)
signal m_button_pressed(window)
signal r_button_pressed(window)

@onready 
var text = %Text
@onready 
var l_button = %LButton
@onready 
var m_button = %MButton
@onready 
var r_button = %RButton

var content:
	set(value):
		text.text = value
	get:
		return text.text

var l_button_text:
	set(value):
		l_button.text = value
	get:
		return l_button.text

var m_button_text:
	set(value):
		m_button.text = value
	get:
		return m_button.text

var r_button_text:
	set(value):
		r_button.text = value
	get:
		return r_button.text

func close():
	var par = get_parent()
	if par != null:
		visible = false
		par.remove_child(self)
		queue_free()

func _ready():
	l_button.pressed.connect(func(): l_button_pressed.emit(self))
	m_button.pressed.connect(func(): m_button_pressed.emit(self))
	r_button.pressed.connect(func(): r_button_pressed.emit(self))
	$PanelContainer.sort_children.connect(func():
		var my = $PanelContainer/MarginContainer/VBoxContainer.size.y
		var mx = max($PanelContainer/MarginContainer/VBoxContainer/MarginContainer.size.x, $PanelContainer/MarginContainer/VBoxContainer/MarginContainer2.size.x)
		var s = Vector2i(roundi(mx), roundi(my))
		min_size = s
		max_size = s
		)

