@tool
extends Node

@export var _text: NodePath
@onready var text: RichTextLabel2 = get_node(_text)

@export var _btn_refresh: NodePath
@onready var btn_refresh: Button = get_node(_btn_refresh)

@export var _filter: NodePath
@onready var filter: LineEdit = get_node(_filter)
@export var _tags_panel: NodePath
@onready var tags_panel: HFlowContainer = get_node(_tags_panel)
var all_tags := []
var enabled_tags := {}

@export var _tog_private: NodePath
@onready var tog_private: CheckButton = get_node(_tog_private)

@export var plugin_instance_id: int

var _hashed := {}

func _ready() -> void:
	text.pressed.connect(_pressed)
	text._connect_meta()
	btn_refresh.pressed.connect(_refresh)
	filter.text_changed.connect(_filter_changed)
	tog_private.toggled.connect(_redraw)

func _filter_changed(t: String):
	text.filter = t
	_redraw()

func _pressed(flow: Dictionary):
	var plugin = instance_from_id(plugin_instance_id)
	if plugin:
		plugin.edit_text_file(flow.file, flow.line)
	else:
		push_error("ChapterPanel: Not called from plugin: %s" % flow)

func _refresh():
	_redraw()

func _sort(a: Array, b: Array):
	return a[2] < b[2]

func sorted(d: Dictionary) -> Array:
	var a := []
	for k in d:
		if k != "_F_" and k != "_P_":
			a.append([k, d[k], d[k]._F_.M.get("rank", "0").to_int()])
	a.sort_custom(_sort)
	return a

func _collect(id: String, d: Dictionary, out: Array, deep: int):
	# skip private
	if not tog_private.button_pressed and id.begins_with("_"):
		return
	
	var info: Dictionary = d._F_
	var tags: Array = info.M.get("tags", "").strip_edges().split(" ", false)
	
	# check if has all tags
	if _has_tags(tags):
		var icon: String = info.M.get("icon", "[:black_medium_square:]")
		var progress = info.M.get("progress", "0").to_float() / 100.0
		var tabs := "  ".repeat(deep)
		var note: String = info.M.get("note", "")
		var tint: Color = Soot.get_flow_color(deep)
		var prog := "[bg %s;%s;hint %.2d]%s[]" % [Color.WEB_GRAY, Color.TOMATO.lerp(Color.GREEN_YELLOW, progress), progress*100.0, Emoji.progress(progress, 2)]
		var label := "%s%s%s" % [icon, tabs, "[%s]%s[] [dim]%s[]" % [tint, id, note]]
		out.append("\t".repeat(deep) + prog + text.do_clickable(label, info.M))
		
		# go through children
		for item in sorted(d):
			_collect(item[0], item[1], out, deep + 1)
	
	return out

func _toggle_tag(toggled: bool, tag: String):
	enabled_tags[tag] = toggled
	_redraw()

func _has_tags(tags: Array) -> bool:
	for tag in enabled_tags:
		if enabled_tags[tag] and tag in all_tags:
			if not tag in tags:
				return false
	return true

func _redraw(_x=null):
	all_tags.clear()
	UNode.remove_children(tags_panel)
	
	var tree := {}
	for flow in Sooty.dialogue.flows:
		var info: Dictionary = Sooty.dialogue.flows[flow]
		var tags: Array = info.M.get("tags", "").strip_edges().split(" ", false)
		
		for tag in tags:
			if not tag in all_tags:
				all_tags.append(tag)
				var btn := CheckBox.new()
				btn.text = tag
				btn.button_pressed = enabled_tags.get(tag, false)
				btn.toggled.connect(_toggle_tag.bind(tag))
				tags_panel.add_child(btn)
		
		UDict.set_at(tree, flow.split("/"), {_P_=flow, _F_=info})
	
	var out := []
	for item in sorted(tree):
		_collect(item[0], item[1], out, 0)
	text.set_bbcode("\n".join(out))
