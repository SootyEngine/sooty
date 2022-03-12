@tool
extends Container
class_name FE_Editors

const FONT_SIZE_MIN := 4
const FONT_SIZE_MAX := 64
const PATH_EDITOR := "res://addons/file_editor/ext_editor/%s_editor.gd"
const PATH_HIGHLIGHTER := "res://addons/file_editor/ext_editor/%s_highlighter.gd"

# requests
enum { R_SAVE, R_CLOSE_CURRENT, R_SETTINGS_CHANGED, R_CLOSE_TEMPORARY }

signal current_editor_changed()
signal request(request: int)

@export var _meta_panel: NodePath
@export var _error_label: NodePath
@export var _meta_label: NodePath
@onready var meta_panel: Control = get_node(_meta_panel)  
@onready var error_label: Control = get_node(_error_label)  
@onready var meta_label: Control = get_node(_meta_label)  

@export var word_wrap := false
@export var font_size := 16:
	set(e): font_size = clampi(e, FONT_SIZE_MIN, FONT_SIZE_MAX)

var current_tab: int:
	set(x): $tab_bar.set_current_tab.call_deferred(x)
	get: return $tab_bar.current_tab

var _save_queue := []
var _recently_closed := []

func _ready() -> void:
	$tab_bar.current_changed.connect(_tab_changed)
	$editor_parent.child_entered_tree.connect(_tab_changed)
	$editor_parent.child_exited_tree.connect(_tab_changed)

func has_editors() -> bool:
	return $editor_parent.get_child_count() > 0

func get_editors():
	return $editor_parent.get_children()

func _tab_changed(_x=null):
	current_editor_changed.emit()

func queue_save(msg: String, call: Callable):
	_save_queue.append([msg, call])
	set_process(true)

func _process(delta: float) -> void:
	if len(_save_queue):
		var data = _save_queue.pop_front()
		print("SAVE MSG: ", data[0])
		data[1].call()
	else:
		set_process(false)

func _unhandled_input(e: InputEvent) -> void:
	if owner.visible and e is InputEventKey:
		if e.pressed:
			if e.ctrl_pressed:
				match e.keycode:
					KEY_Q: self.word_wrap = not word_wrap
					KEY_PLUS, KEY_EQUAL: self.font_size += 1
					KEY_MINUS: self.font_size -= 1
					KEY_S: request.emit(R_SAVE)
					KEY_W: request.emit(R_CLOSE_CURRENT)
#					_: print(e.keycode)
	
	elif e is InputEventMouseButton:
		if e.pressed:
			if e.ctrl_pressed:
				match e.button_index:
					MOUSE_BUTTON_WHEEL_UP: self.font_size += 1
					MOUSE_BUTTON_WHEEL_DOWN: self.font_size -= 1

func _create_editor(file: FE_File) -> FE_Editor:
	var path := PATH_EDITOR % file.extension
	var out: FE_Editor
	if File.new().file_exists(path):
		out = load(path).new(file)
	else:
		push_error("No editor for extension '%s'." % file.extension)
		out = FE_Editor.new(file)
	
	out.set_syntax_highlighter(_create_highlighter(file))
	$editor_parent.add_child(out)
	out.set_owner(owner)
	return out

func _create_highlighter(file: FE_File) -> SyntaxHighlighter:
	var path := PATH_HIGHLIGHTER % file.extension
	if File.new().file_exists(path):
		return load(path).new()
	return CodeHighlighter.new()

func open(file: FE_File) -> FE_Editor:
	var tab := get_editor(file)
	if tab:
		if tab.is_temporary:
			tab.is_temporary = false
	else:
		request.emit(R_CLOSE_TEMPORARY)
		tab = _create_editor(file)
	self.current_tab = tab.get_index()
	return tab

func get_editor(file: FE_File) -> FE_Editor:
	for tab in $editor_parent.get_children():
		if "file" in tab and tab.file == file:
			return tab
	return null

func get_current_editor() -> FE_Editor:
	if current_tab < $editor_parent.get_child_count():
		return $editor_parent.get_child(current_tab)
	return null

func get_current_file() -> FE_File:
	if has_editors():
		return $editor_parent.get_child(current_tab).file
	return null
