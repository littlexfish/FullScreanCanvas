## Deprecated: Unnecessary to use
extends Window

func _ready():
	$FileExplore.hide_request.connect(func():queue_free())


func get_explore():
	return $FileExplore
