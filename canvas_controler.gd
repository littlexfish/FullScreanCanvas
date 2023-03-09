extends Panel

const PEN_DISABLE_COLOR = Color(0.5, 0.5, 0.5)
const POPUP_WINDOW = preload("res://PopupWindow.tscn")


@onready 
var pen = $VBoxContainer/MarginContainer/HBoxContainer/Pens/Pen/Pen
@onready
var highlighter = $VBoxContainer/MarginContainer/HBoxContainer/Pens/Highlighter/Highlighter
@onready 
var rect = $VBoxContainer/MarginContainer/HBoxContainer/Pens/Rect/Rect
@onready 
var circle = $VBoxContainer/MarginContainer/HBoxContainer/Pens/Circle/Circle
@onready
var penModeNodes = [pen, highlighter, rect, circle]

var selectedPen: TextureButton

@onready 
var normal = $VBoxContainer/MarginContainer/HBoxContainer/CanvasMode/Normal
@onready 
var unreachable = $VBoxContainer/MarginContainer/HBoxContainer/CanvasMode/UnReach
@onready 
var hide = $VBoxContainer/MarginContainer/HBoxContainer/CanvasMode/Hide
@onready
var canvasModeNodes = [normal, unreachable, hide]

var mainNode

# Called when the node enters the scene tree for the first time.
func _ready():
	normal.pressed.connect(canvasModeChange.bind(normal))
	unreachable.pressed.connect(canvasModeChange.bind(unreachable))
	hide.pressed.connect(canvasModeChange.bind(hide))
	$VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer/Filled.pressed.connect(func():
		$VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer/PenSize.visible = \
			not $VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer/Filled.button_pressed
		)
	pen.pressed.connect(penModeChange.bind(pen))
	highlighter.pressed.connect(penModeChange.bind(highlighter))
	rect.pressed.connect(penModeChange.bind(rect))
	circle.pressed.connect(penModeChange.bind(circle))
	
	selectedPen = pen
	$VBoxContainer/MarginContainer/HBoxContainer/ColorPickerButton.color_changed.connect(func(_color):
		selectedPen.self_modulate = get_pen_color()
		)
	
	for p in penModeNodes:
		p.self_modulate = PEN_DISABLE_COLOR
	selectedPen.self_modulate = get_pen_color()
	
	%BackColor.color = mainNode.canvas.background
	%BackColor.color_changed.connect(func(color):
		mainNode.canvas.background = color
		mainNode.canvas.queue_redraw()
		)
	
	if DisplayServer.get_screen_count() <= 1:
		%File.get_popup().set_item_disabled(4, true)
	
	%File.get_popup().id_pressed.connect(func(id):
		match id:
			0: # New
				emit_new()
			1: # Save
				emit_save()
				
			2: # Save As
				emit_save_as()
			4: # Switch Screen
				emit_switch_screen()
		)
	%Edit.get_popup().id_pressed.connect(func(id):
		match id:
			0: # undo
				mainNode.canvas.do_undo()
			1: # redo
				mainNode.canvas.do_redo()
		)

func emit_save():
	var can = mainNode.canvas
	if can.isSave: return
	if can.savingPath == '':
		save_image(func(path):
			can.savingPath = path
			can.isSave = true
			)
	else:
		mainNode.save(can.savingPath, can.savingPath.rsplit('.', false, 1)[-1])

func emit_save_as():
	var can = mainNode.canvas
	save_image(func(path):
		can.savingPath = path
		can.isSave = true
		, 'Save As')

func emit_new():
	var can = mainNode.canvas
	if not can.isSave:
		var w = POPUP_WINDOW.instantiate()
		add_child(w)
		w.content = 'not yet save!'
		w.l_button_text = 'cancel'
		w.m_button_text = "don't save"
		w.r_button_text = 'save'
		w.l_button_pressed.connect(func(window): window.close())
		w.m_button_pressed.connect(func(window):
			window.close()
			clear_canvas()
			)
		w.r_button_pressed.connect(func(window):
			window.close()
			save_image(clear_canvas)
			)
		w.close_requested.connect(func(): w.l_button.pressed.emit())

func emit_switch_screen():
	var window = Window.new()
	window.title = 'Choose Screen'
	var c = preload("res://SwitchScreen.tscn").instantiate()
	window.add_child(c)
	var screenCount = DisplayServer.get_screen_count()
	var nowScreen = mainNode.get_window().current_screen
	c.set_value(screenCount - 1, nowScreen)
	window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	c.on_ok.connect(func(idx):
		mainNode.set_screen(idx))
	add_child(window)

func setUndoEnable(flag: bool):
	%Edit.get_popup().set_item_disabled(0, not flag)

func setRedoEnable(flag: bool):
	%Edit.get_popup().set_item_disabled(1, not flag)

func clear_canvas(_path = null):
	mainNode.canvas.clear()
	mainNode.raise_canvas()

func save_image(additionFunc: Callable, title := 'Save'):
	var can = mainNode.canvas
	var fileDialog = FileDialog.new()
	fileDialog.title = title
	fileDialog.access = FileDialog.ACCESS_FILESYSTEM
	if can.savingPath == '':
		fileDialog.current_file = 'untitled.png'
		fileDialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	else:
		fileDialog.current_path = can.savingPath
	fileDialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	# FIXME: filter in FileDialog has some problem
	fileDialog.add_filter('png', '.png')
	fileDialog.add_filter('jpg', '.jpg')
	fileDialog.add_filter('webp', '.webp')
	fileDialog.add_filter('exr', '.exr')
	fileDialog.file_selected.connect(func(path: String):
		var spl = path.rsplit('.', false, 1)
		var ext = spl[1]
		if ext.begins_with('jpg'):
			ext = 'jpg'
		elif ext.begins_with('exr'):
			ext = 'exr'
		elif ext.begins_with('webp'):
			ext = 'webp'
		else:
			ext = 'png'
		mainNode.save(spl[0] + '.' + ext, ext)
		fileDialog.queue_free()
		mainNode.raise_controller()
		additionFunc.call(path)
		)
	fileDialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	fileDialog.size = Vector2i(720, 480)
	add_child(fileDialog)
	fileDialog.show()

func get_pen_size() -> float:
	return $VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer/PenSize.value / 100.0

func get_pen_color() -> Color:
	if highlighter.disabled:
		return Color($VBoxContainer/MarginContainer/HBoxContainer/ColorPickerButton.color, 0.5)
	return $VBoxContainer/MarginContainer/HBoxContainer/ColorPickerButton.color

func get_pen_mode() -> int:
	return Canvas.D_RECT if rect.disabled else Canvas.D_CIRCLE if circle.disabled else Canvas.D_LINE

func get_pen_filled() -> bool:
	return $VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer/Filled.button_pressed

func penModeChange(obj):
	for p in penModeNodes:
		p.disabled = p == obj
	for p in penModeNodes:
		if p.disabled:
			selectedPen = p
			p.self_modulate = get_pen_color()
		else:
			p.self_modulate = PEN_DISABLE_COLOR
	if rect.disabled or circle.disabled:
		$VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer/Filled.visible = true
		$VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer/PenSize.visible = \
			not $VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer/Filled.button_pressed
	else:
		$VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer/Filled.visible = false
		$VBoxContainer/MarginContainer/HBoxContainer/HBoxContainer/PenSize.visible = true

func canvasModeChange(obj):
	var allFalse = true
	for c in canvasModeNodes:
		if c.button_pressed:
			allFalse = false
			break
	if allFalse:
		obj.button_pressed = true
	else:
		for c in canvasModeNodes:
			c.button_pressed = true if c == obj else false
	_changeCanvasMode()
	
func _changeCanvasMode():
	if normal.button_pressed:
		mainNode.enable = true
		mainNode.canFocus = true
		mainNode.raise_controller()
	elif unreachable.button_pressed:
		mainNode.enable = true
		mainNode.canFocus = false
		mainNode.raise_controller()
	else:
		mainNode.enable = false
		mainNode.canFocus = true
		mainNode.raise_controller()
	mainNode.check_canvas_screen_idx()

func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			if event.is_command_or_control_pressed():
				match event.keycode:
					KEY_Z:
						if event.shift_pressed:
							mainNode.canvas.do_redo()
						else:
							mainNode.canvas.do_undo()
					KEY_Y:
						mainNode.canvas.do_redo()
					KEY_M:
						mainNode.controller.emit_switch_screen()
					KEY_N:
						mainNode.controller.emit_new()
					KEY_S:
						if event.shift_pressed:
							mainNode.controller.emit_save_as()
						else:
							mainNode.controller.emit_save()
				return
			match event.keycode:
				KEY_ESCAPE:
					mainNode.raise_controller()
