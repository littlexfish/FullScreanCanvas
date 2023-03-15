extends Node2D

var enable = true :
	set(value):
		get_tree().get_root().mode = Window.MODE_FULLSCREEN if value else Window.MODE_MINIMIZED
		$DrawingPreview.enable = value
		$Canvas.enable = value

var canFocus = true :
	set(value):
		canFocus = value
		get_tree().get_root().unfocusable = not value

var isMousePressed = false


var conWindow: Window
@onready
var controller = preload('res://canvas_controler.tscn').instantiate()
@onready 
var canvas = $Canvas

var canvasScreen = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().transparent_bg = true
	var w = Window.new()
	w.title = 'Controller'
	w.close_requested.connect(func(): 
		if not canvas.isSave:
			var wi = preload("res://PopupWindow.tscn").instantiate()
			add_child(wi)
			wi.content = 'not yet save!'
			wi.l_button_text = 'cancel'
			wi.m_button_text = "don't save"
			wi.r_button_text = 'save'
			wi.l_button_pressed.connect(func(window): window.close())
			wi.m_button_pressed.connect(func(window):
				window.close()
				get_tree().quit()
				)
			wi.r_button_pressed.connect(func(window):
				window.close()
				controller.save_image(func(_path): get_tree().quit())
				)
			wi.close_requested.connect(func(): w.l_button.pressed.emit())
		else:
			get_tree().quit()
		)
	w.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
#	w.wrap_controls = true
	w.size = Vector2(550, 100)
	w.min_size = Vector2i(550, 100)
	w.max_size = Vector2i(900, 200)
	controller.mainNode = self
	w.add_child(controller)
	conWindow = w
	add_child(w)
	
	canvasScreen = get_window().current_screen


func raise_canvas():
	var w = get_window()
	if not w.has_focus():
		w.grab_focus()


func raise_controller():
	if not conWindow.has_focus():
		conWindow.grab_focus()


func save(path: String, ext: String):
	var img = get_viewport().get_texture().get_image()
	match ext:
		'jpg':
			img.save_jpg(path)
		'png':
			img.save_png(path)
		'webp':
			img.save_webp(path)
		'exr':
			img.save_exr(path)

func set_screen(screenIdx: int):
	if screenIdx < 0 or screenIdx >= DisplayServer.get_screen_count():
		return
	canvasScreen = screenIdx
	check_canvas_screen_idx()

func check_canvas_screen_idx():
	var w = get_window()
	if w.current_screen != canvasScreen:
		get_window().current_screen = canvasScreen

func _unhandled_input(event):
	if event is InputEventKey:
		if event.is_pressed():
			if event.is_command_or_control_pressed():
				match event.keycode:
					KEY_Z:
						if event.shift_pressed:
							canvas.do_redo()
						else:
							canvas.do_undo()
					KEY_Y:
						canvas.do_redo()
					KEY_M:
						controller.emit_switch_screen()
					KEY_N:
						controller.emit_new()
					KEY_S:
						if event.shift_pressed:
							controller.emit_save_as()
						else:
							controller.emit_save()
					_:
						return
				_handle_input()
				return
			match event.keycode:
				KEY_ESCAPE:
					raise_controller()
				_: 
					return
			_handle_input()
			return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			isMousePressed = event.is_pressed()
			if isMousePressed:
				$DrawingPreview.on_draw_first(event.position)
			else:
				$DrawingPreview.on_draw_end()
			_handle_input()
	if event is InputEventMouseMotion:
		if isMousePressed:
			$DrawingPreview.on_draw(event.relative)
			_handle_input()

func _handle_input():
	get_viewport().set_input_as_handled()




