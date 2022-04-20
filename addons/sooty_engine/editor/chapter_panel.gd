@tool
extends Node

@export var _text: NodePath
@onready var text: RichTextLabel2 = get_node(_text)

@export var _btn_refresh: NodePath
@onready var btn_refresh: Button = get_node(_btn_refresh)

@export var _filter: NodePath
@onready var filter: LineEdit = get_node(_filter)

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
	if tog_private.button_pressed and id.begins_with("_"):
		return
	
	var info: Dictionary = d._F_
	var icon: String = info.M.get("icon", "[:black_medium_square:]")
	
	var progress = info.M.get("progress", "0").to_float() / 100.0
	var tabs := "  ".repeat(deep)
	var note: String = info.M.get("note", "")
	var tint: Color = Soot.get_flow_color(deep)
	var prog := "[bg %s;%s;hint %.2d]%s[]" % [Color.WEB_GRAY, Color.TOMATO.lerp(Color.GREEN_YELLOW, progress), progress*100.0, Emoji.progress(progress, 2)]
	var label := "%s%s%s" % [icon, tabs, "[%s]%s[] [dim]%s[]" % [tint, id, note]]
	out.append("\t".repeat(deep) + prog + text.do_clickable(label, info.M))
	
	for item in sorted(d):
		_collect(item[0], item[1], out, deep + 1)
	return out

func _redraw(_x=null):
	var tree := {}
	for flow in Dialogue._flows:
		UDict.set_at(tree, flow.split("/"), {_P_=flow, _F_=Dialogue._flows[flow]})
	
	var out := []
	for item in sorted(tree):
		_collect(item[0], item[1], out, 0)
	text.set_bbcode("\n".join(out))
	
#	var lines := []
#	text.clear_meta()
#
#	var last_deep := 0
#	for flow in Dialogue._flows:
#		var parts = flow.split("/")
#		var deep = len(parts)
#		var data = Dialogue._flows[flow]
#		var label := "%s%s" % ["\t\t".repeat(deep-1), parts[-1]]
#		var color := Color.WHITE.darkened(.2 * deep)
#
#		var metas := []
#		var end_metas := []
#		var icon := ""
#		var progress := 0.0
#
#		for k in data.M:
#			if not k in ["id", "file", "line"]:
#				if k == "color":
#					color = UStringConvert.to_color(data.M[k]).darkened(.2 * (deep-1))
#					continue
#				elif k == "icon":
#					icon = data.M[k]
#					continue
#				elif k == "note":
#					end_metas.append("[dima;i]%s[]" % [data.M[k]])
#					continue
#				elif k == "progress":
#					progress = data.M[k].trim_suffix("%").to_float() / 100.0
#					continue
#				end_metas.append("[dim]%s:[]%s" % [k, data.M[k]])
#
#		metas.append("[%s;hint %.2f] ■ []" % [Color.TOMATO.lerp(Color.YELLOW_GREEN, progress), progress*100.0])
#		metas.append(icon)
#		metas.append(text.gen_meta("[%s;b]%s[]" % [color, label], data, data.M.file))
#
#		lines.append(" ".join(metas + end_metas))
#		last_deep = deep
		
#	text.set_bbcode("\n".join(lines))
