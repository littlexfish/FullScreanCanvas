extends Window

signal folder_create(n: String)

# Called when the node enters the scene tree for the first time.
func _ready():
	%OK.pressed.connect(func():
		if not %Folder.text.empty():
			queue_free()
			folder_create.emit(%Folder.text)
		)
	%Cancel.pressed.connect(func(): queue_free())
	close_requested.connect(func(): queue_free())

