extends Node2D

class_name Canvas

const ARC_POINTS = 64

const D_LINE = 0
const D_RECT = 1
const D_CIRCLE = 2

var enable = true:
	set(value):
		enable = value
		visible = value

var savingPath = ''
var isSave = true

var undo_redo = UndoRedo.new()
var paths = []
var nowSize = 5.0
var nowColor = Color.RED
var background = Color(0, 0, 0, 0)

func _ready():
	pass # Replace with function body.

func do(dict: Dictionary):
	paths.append(dict)
	get_parent().controller.setRedoEnable(undo_redo.has_redo())
	get_parent().controller.setUndoEnable(undo_redo.has_undo())
	queue_redraw()

func undo(dict: Dictionary):
	paths.erase(dict)
	get_parent().controller.setRedoEnable(undo_redo.has_redo())
	get_parent().controller.setUndoEnable(undo_redo.has_undo())
	queue_redraw()

func do_undo():
	undo_redo.undo()
	get_parent().controller.setRedoEnable(undo_redo.has_redo())
	get_parent().controller.setUndoEnable(undo_redo.has_undo())

func do_redo():
	undo_redo.redo()
	get_parent().controller.setRedoEnable(undo_redo.has_redo())
	get_parent().controller.setUndoEnable(undo_redo.has_undo())

func clear():
	isSave = true
	paths.clear()
	undo_redo.clear_history()
	get_parent().controller.setRedoEnable(undo_redo.has_redo())
	get_parent().controller.setUndoEnable(undo_redo.has_undo())
	queue_redraw()

func set_background(color: Color):
	background = color

func draw_lines(ps: PackedVector2Array, size: float = 1.0):
	if ps.is_empty(): return
	var dict = {}
	dict.type = D_LINE
	dict.size = absf(size)
	dict.color = nowColor
	dict.path = ps
	undo_redo.create_action('Draw lines')
	undo_redo.add_do_method(do.bind(dict))
	undo_redo.add_undo_method(undo.bind(dict))
	undo_redo.add_do_property(self, 'isSave', false)
	undo_redo.add_undo_property(self, 'isSave', isSave)
	undo_redo.commit_action()

func draw_rectangle(start: Vector2, size: Vector2, filled := false):
	var dict = {}
	dict.type = D_RECT
	dict.rect = Rect2(start, size).abs()
	dict.width = absf(nowSize)
	dict.color = nowColor
	dict.filled = filled
	undo_redo.create_action('Draw rect')
	undo_redo.add_do_method(do.bind(dict))
	undo_redo.add_undo_method(undo.bind(dict))
	undo_redo.add_do_property(self, 'isSave', false)
	undo_redo.add_undo_property(self, 'isSave', isSave)
	undo_redo.commit_action()

func draw_circle_t(pos: Vector2, rad: float, filled := false):
	var dict = {}
	dict.type = D_CIRCLE
	dict.pos = pos
	dict.rad = rad
	dict.color = nowColor
	dict.width = absf(nowSize)
	dict.filled = filled
	undo_redo.create_action('Draw circle')
	undo_redo.add_do_method(do.bind(dict))
	undo_redo.add_undo_method(undo.bind(dict))
	undo_redo.add_do_property(self, 'isSave', false)
	undo_redo.add_undo_property(self, 'isSave', isSave)
	undo_redo.commit_action()


func _draw():
	draw_rect(get_viewport_rect(), background, true)
	for d in paths:
		var dict = d as Dictionary
		var type = dict.type as int
		match type:
			D_LINE:
				_draw_lines(dict)
			D_RECT:
				_draw_rect(dict)
			D_CIRCLE:
				_draw_circle(dict)

func _draw_lines(dict: Dictionary):
	var size = dict.size as float
	var color = dict.color as Color
	var path = dict.path as PackedVector2Array
	draw_multiline(path, color, size)

func _draw_rect(dict: Dictionary):
	var filled = dict.filled as bool
	var rect = dict.rect as Rect2
	var color = dict.color as Color
	var width = dict.width as float
	draw_rect(rect, color, filled, width if not filled else -1.0)

func _draw_circle(dict: Dictionary):
	var filled = dict.filled as bool
	var pos = dict.pos as Vector2
	var rad = dict.rad as float
	var color = dict.color as Color
	var width = dict.width as float
	if filled:
		draw_circle(pos, rad, color)
	else:
		draw_arc(pos, rad, 0, TAU, ARC_POINTS, color, width, true)






