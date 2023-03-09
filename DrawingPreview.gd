extends Node2D

const ARC_POINTS = 64

var enable = true
var drawMode = Canvas.D_LINE

var size = 0.0
var color = Color.RED
var segments = PackedVector2Array()
var rect = Rect2()
var circlePos = Vector2()
var circleRad = 0.0
var filled = false
var prePos = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _get_controller():
	return get_parent().controller

func _get_canvas():
	return get_parent().canvas

func on_draw_first(pos: Vector2):
	if not enable: return
	var con = _get_controller()
	size = con.get_pen_size()
	color = con.get_pen_color()
	drawMode = con.get_pen_mode()
	filled = con.get_pen_filled()
	prePos = pos
	match drawMode:
		Canvas.D_LINE:
			segments.append(pos)
			segments.append(pos)
		Canvas.D_RECT:
			rect.position = pos
			rect.end = pos
		Canvas.D_CIRCLE:
			circlePos = pos

func on_draw(vecFromPre: Vector2):
	if not enable: return
	match drawMode:
		Canvas.D_LINE:
			segments.append(prePos)
			prePos += vecFromPre
			segments.append(prePos)
		Canvas.D_RECT:
			prePos += vecFromPre
			rect.end = prePos
		Canvas.D_CIRCLE:
			prePos += vecFromPre
			circleRad = prePos.distance_to(circlePos)
	queue_redraw()
	

func on_draw_end():
	if not enable: return
	var can = _get_canvas()
	can.nowColor = color
	can.nowSize = size
	match drawMode:
		Canvas.D_LINE:
			can.draw_lines(segments.duplicate(), size)
			segments.clear()
		Canvas.D_RECT:
			var absR = rect.abs()
			can.draw_rectangle(absR.position, absR.size, filled)
			rect.position = Vector2()
			rect.end = Vector2()
		Canvas.D_CIRCLE:
			can.draw_circle_t(circlePos, circleRad, filled)
			circlePos = Vector2()
			circleRad = 0.0
	queue_redraw()


func _draw():
	match drawMode:
		Canvas.D_LINE:
			if not segments.is_empty():
				draw_multiline(segments, color, size)
		Canvas.D_RECT:
			draw_rect(rect.abs(), color, filled, size if not filled else -1.0)
		Canvas.D_CIRCLE:
			if filled:
				draw_circle(circlePos, circleRad, color)
			else:
				draw_arc(circlePos, circleRad, 0, TAU, ARC_POINTS, color, size, true)


