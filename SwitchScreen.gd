extends PanelContainer

signal on_ok

# Called when the node enters the scene tree for the first time.
func _ready():
	%Cancel.pressed.connect(func(): get_parent().queue_free())
	%OK.pressed.connect(func(): 
		on_ok.emit(%HSlider.value)
		get_parent().queue_free())
	
	%HSlider.value_changed.connect(func(value):
		%Value.text = str(floor(value)))
	
	var s = Vector2i(500, 100)
	get_window().size = s
	get_window().min_size = s
	get_window().max_size = s
	get_window().close_requested.connect(func(): get_parent().queue_free())


func set_value(x: int, now: int):
	%HSlider.min_value = 0
	%HSlider.max_value = x
	%HSlider.value = now

