extends PanelContainer

const FOLDER_CREATER = preload("res://FileExplore/FolderCreater.tscn")
const FILE_IMG = preload("res://assets/file.svg")
const DIR_IMG = preload("res://assets/folder.svg")

signal hide_request()
signal change_file(path: String)
signal select_file(path: String)

@onready var directory = %Directory
@onready var files = %Files
@onready var file = %File
@onready var filter = %Filter

var undo_redo = UndoRedo.new()

var filters = {}
var nextFilterId = 1

var nowDirectory = "./"

func _ready():
	%Back.pressed.connect(func(): do_back())
	%Front.pressed.connect(func(): do_front())
	%UpDir.pressed.connect(func(): do_upDir())
	%Refresh.pressed.connect(func(): do_refresh())
	%ShowHide.pressed.connect(func(): do_showHide())
	%CreateFolder.pressed.connect(func(): do_createFolder())
	%OK.pressed.connect(func(): on_ok())
	%Cancel.pressed.connect(func(): on_cancel())
	
	var dir = DirAccess.open(nowDirectory)
	nowDirectory = dir.get_current_dir()
	
	
	%Files.item_selected.connect(func(idx: int):
		var texture = %Files.get_item_icon(idx)
		if texture != DIR_IMG:
			var text = %Files.get_item_text(idx)
			%File.text = text
			change_file.emit(nowDirectory.path_join(text))
		)
	%Files.item_activated.connect(func(idx: int): 
		var texture = %Files.get_item_icon(idx)
		var text = %Files.get_item_text(idx)
		if texture == DIR_IMG:
			get_in_folder(text)
		else:
			%File.text = text
			on_ok()
		)
	%Filter.item_selected.connect(func(idx: int):
		var id = %Filter.get_item_id(idx)
		if not id in [0, 50]:
			var nameSpl = %File.text.rsplit('.', false, 1)
			var ext = filters[id]
			%File.text = nameSpl[0] + ext
		)

func undo_and_redo(path: String):
	nowDirectory = path
	do_refresh()

func do_back():
	undo_redo.undo()
	%Back.disabled = not undo_redo.has_undo()
	%Front.disabled = not undo_redo.has_redo()

func do_front():
	undo_redo.redo()
	%Back.disabled = not undo_redo.has_undo()
	%Front.disabled = not undo_redo.has_redo()

func do_upDir(history := true):
	var spl = nowDirectory.rsplit('/', false, 1)
	if spl[0] == nowDirectory:
		return
	var tmp = nowDirectory
	spl.resize(spl.size() - 1)
	nowDirectory = '/'.join(spl)
	if history:
		undo_redo.create_action('Go To Parent Folder')
		undo_redo.add_do_method(undo_and_redo.bind(nowDirectory))
		undo_redo.add_undo_method(undo_and_redo.bind(tmp))
		undo_redo.commit_action()
	else:
		do_refresh()


func do_refresh():
	var dir = DirAccess.open(nowDirectory)
	if dir.get_open_error() == ERR_FILE_NOT_FOUND:
		do_upDir(false)
	dir.include_hidden = %ShowHide.button_pressed
	dir.include_navigational = false
	var dirs = dir.get_directories()
	var dirCount = dirs.size()
	for di in range(dirCount):
		if di >= %Files.item_count:
			%Files.add_item(dirs[di], DIR_IMG)
		else:
			%Files.set_item_icon(di, DIR_IMG)
			%Files.set_item_text(dirs[di])
	var filt = filters[%Filter.get_item_id(%Filter.selected)]
	var fs = dir.get_files()
	var fCount = fs.size()
	if filt != '.*': # All File
		if filt == '.': # All Filter
			var onlyFilt = filters.duplicate()
			onlyFilt.erase(0)
			onlyFilt.erase(50)
			for i in range(fCount - 1, -1, -1):
				for f in onlyFilt:
					if fs[i].ends_with(f):
						continue
				fs.remove_at(i)
		else:
			for i in range(fCount - 1, -1, -1):
				if not fs[i].ends_with(filt):
					fs.remove_at(i)
		fCount = fs.size()
	for fi in range(fCount):
		var fIdx = fi + dirCount
		if fIdx >= %Files.item_count:
			%Files.add_item(fs[fi], FILE_IMG)
		else:
			%Files.set_item_icon(fIdx, FILE_IMG)
			%Files.set_item_text(fs[fi])
	if %Files.item_count > dirCount + fCount:
		for i in range(dirCount + fCount, %Files.item_count):
			%Files.remove_item(i)

func do_showHide():
	do_refresh()

func do_createFolder():
	var folderC = FOLDER_CREATER.instantiate()
	folderC.folder_create.connect(func(n: String):
		var dir = DirAccess.open(nowDirectory)
		dir.make_dir(n)
		do_refresh()
		)
	add_child(folderC)
	folderC.show()

func on_ok():
	var path = nowDirectory.path_join(%File.text)
	select_file.emit(nowDirectory.path_join(path))
	hide_request.emit()

func on_cancel():
	hide_request.emit()

func get_in_folder(folder_name: String):
	nowDirectory = nowDirectory.path_join(folder_name)
	do_refresh()

func pre_show():
	if not filters.is_empty():
		var fs = ''
		for i in range(1, filters.size()):
			if i > 1:
				fs += ', '
			fs += filters[i][0]
		%Filter.set_item_text(0, 'All Accept Extension (%s)' % [fs])
	filters[50] = [".*", "All Files (*)"]


func add_filter(ext: String, des: String):
	if nextFilterId >= 50:
		push_warning('too many filter')
		return
	if filters.is_empty():
		filters[0] = [".", ""]
		%Filter.add_item(".", 0)
	%Filter.add_item(des, nextFilterId)
	filters[nextFilterId] = [ext, des]
	nextFilterId += 1
	
