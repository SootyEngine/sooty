@tool
extends Control

const FE_Main := preload("res://addons/file_editor/comp/FE_Main.gd")
const FE_Files := preload("res://addons/file_editor/comp/FE_Files.gd")
const FE_Editors := preload("res://addons/file_editor/comp/FE_Editors.gd")
const FE_OptionsMenu := preload("res://addons/file_editor/FE_OptionsMenu.gd")

@export var _popup: NodePath
@export var _filter: NodePath
@export var _list: NodePath
@onready var popup: PopupMenu = get_node(_popup)
@onready var filter: LineEdit = get_node(_filter)
@onready var list: RichTextLabel = get_node(_list)

var fe_main: FE_Main:
	get: return owner

var files: FE_Files:
	get: return fe_main.files

var editors: FE_Editors:
	get: return fe_main.editors

const TAB := "  "
var msg_no_items := "No Items"
var filter_text := ""
var items := []
var hovered = null

func _ready() -> void:
	filter.text_changed.connect(_filter_changed)
	list.meta_hover_ended.connect(_hover_ended)
	list.meta_hover_started.connect(_hover_started)
	popup.set_script(FE_OptionsMenu)
	if owner.is_plugin_hint():
		filter.flat = false
	
	for f in ["bold_font_size", "italics_font_size", "bold_italics_font_size", "normal_font_size", "mono_font_size"]:
		list.add_theme_font_size_override(f, 14)

func set_hint(text: String):
	list.hint_tooltip = text

func _filter_changed(f: String):
	filter_text = f
	items_updated()

func _passes_filter(item: Dictionary) -> bool:
	return filter_text == "" or filter_text in item.text.to_lower()

func _hover_started(meta: Variant):
	hovered = meta
	
func _hover_ended(meta: Variant):
	hovered = null
	list.set_tooltip("")

func _input(event: InputEvent) -> void:
	if hovered and event is InputEventMouseButton and event.pressed:
		# left click = select
		if event.button_index == MOUSE_BUTTON_LEFT:
			if hovered is Callable:
				hovered.call()
			else:
				_clicked(hovered)
		
		# right click = show popup
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			popup.show()
			_show_popup(hovered)
			popup.size = Vector2i.ZERO
			popup.position = get_viewport().get_mouse_position()

func _show_popup(meta: Variant):
	pass

func _clicked(meta: Variant):
	pass

func items_updated():
	set_process(true)

func _process(_delta: float) -> void:
	if not fe_main.is_plugin_hint() and Engine.is_editor_hint():
		set_process(false)
		return
	
	list.clear()
	if items:
		for item in items:
			_update_item(item)
			_draw_item(item)
	else:
		list.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
		list.push_color(Color.DIM_GRAY)
		list.append_text("[b]*%s*[/b]" % msg_no_items)
		list.pop()
		list.pop()
	set_process(false)

func _update_item(item: Dictionary):
	item.show = _passes_filter(item)
	
	# check if there are children
	if "children" in item:
		for child in item.children:
			_update_item(child)

func _has_visible_child(item: Dictionary) -> bool:
	if "children" in item:
		for child in item.children:
			if child.show:
				return true
			if _has_visible_child(child):
				return true
	return false

func _draw_item(item: Dictionary):
	if item.show or _has_visible_child(item):
		list.push_meta(item.meta)
		if "deep" in item:
			list.add_text(TAB.repeat(item.deep))
		if "draw" in item:
			item.draw.call()
		else:
			list.append_text(item.text)
		list.pop()
		list.newline()
		_post_draw_item(item)
	
	if "children" in item:
		if "show_children" in item:
			if not item.show_children.call():
				return
		for child in item.children:
			_draw_item(child)

func _push_item(text: String, item: Variant):
	list.push_meta(item)
	list.append_text(text)
	list.pop()
	list.newline()

func _post_draw_item(item: Dictionary):
	pass
