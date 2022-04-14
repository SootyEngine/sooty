@tool
extends Node

@export var _text: NodePath
@onready var text: RichTextLabel2 = get_node(_text)

@export var _btn_refresh: NodePath
@onready var btn_refresh: Button = get_node(_btn_refresh)

@export var plugin_instance_id: int

func _ready() -> void:
#	Mods.loaded.connect(_redraw)
	text.pressed.connect(_pressed)
	text._connect_meta()
	btn_refresh.pressed.connect(_refresh)

func _pressed(flow: Dictionary):
	var plugin = instance_from_id(plugin_instance_id)
	if plugin:
		plugin.edit_text_file(flow.M.file, flow.M.line)
	else:
		push_error("ChapterPanel: %s" % flow)

func _refresh():
	_redraw()

func _redraw():
	var lines := []
	text.clear_meta()
	
	var last_deep := 0
	for flow in Dialogue._flows:
		var parts = flow.split("/")
		var deep = len(parts)
		var data = Dialogue._flows[flow]
		var label := "%s%s" % ["\t".repeat(deep-1), parts[-1]]
		var color := Color.WHITE.darkened(.2 * deep)
		
		var metas := []
		var end_metas := []
		var icon := ""
		var progress := 0.0
		
		for k in data.M:
			if not k in ["id", "file", "line"]:
				if k == "color":
					color = UString.str_to_color(data.M[k]).darkened(.2 * (deep-1))
					continue
				elif k == "icon":
					icon = data.M[k]
					continue
				elif k == "note":
					end_metas.append(data.M[k])
					continue
				elif k == "progress":
					progress = data.M[k].trim_suffix("%").to_float() / 100.0
					continue
				end_metas.append("[dim]%s:[]%s" % [k, data.M[k]])
		
		metas.append("[%s;hint %.2f] ■ []" % [Color.TOMATO.lerp(Color.YELLOW_GREEN, progress), progress*100.0])
		metas.append(icon)
		metas.append(text.gen_meta("[%s;b]%s[]" % [color, label], data, data.M.file))
		
		lines.append(" ".join(metas + end_metas))
		last_deep = deep
		
	text.set_bbcode("\n".join(lines))
