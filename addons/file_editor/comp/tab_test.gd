extends TabBar

signal current_changed()

var _tab_parent: Node
var font := preload("res://fonts/robotomono/robotomono_r.tres")
var font_i := preload("res://fonts/robotomono/robotomono_i.tres")
var font_b := preload("res://fonts/robotomono/robotomono_b.tres")

func get_current_control() -> Node:
	return _tab_parent.get_child(current_tab)

func _ready() -> void:
	_tab_parent = get_parent().get_child(1)
	_tab_parent.child_entered_tree.connect(_child_added)
	_tab_parent.child_exited_tree.connect(_child_removed)
	
#	for i in 4:
#		var tab := CodeEdit.new()
#		tab.set_name("😋Tab_%s%s" % [i, ["st", "nd", "rd", "th"][i]])
#		tab.set_text(str(i).repeat(i+1))
#		_tab_parent.add_child(tab)
	
	active_tab_rearranged.connect(_active_tab_rearranged)
#	tab_button_pressed(tab: int)
	tab_changed.connect(_tab_changed)
#	tab_clicked.connect(_tab_clicked)
	tab_close_pressed.connect(_tab_close_pressed)
#	tab_hovered(tab: int)
#	tab_rmb_clicked(tab: int)
#	tab_selected.connect(set_current_tab)
	
	add_theme_color_override("font_selected_color", Color.TRANSPARENT)
	add_theme_color_override("font_disabled_color", Color.TRANSPARENT)
	add_theme_color_override("font_unselected_color", Color.TRANSPARENT)

func _active_tab_rearranged(index: int):
	_tab_parent.move_child(_tab_parent.get_child(current_tab), index)
	_redo_tabs.call_deferred(index)

func _tab_close_pressed(index: int):
	var editor: FE_Editor = _tab_parent.get_child(index)
	editor.try_close()

func _tab_changed(_index: int):
	current_changed.emit()

func _child_added(node: Node):
	node.title_changed.connect(_titles_changed)
	node.tint_changed.connect(_titles_changed)
	_redo_tabs.call_deferred(_tab_parent.get_child_count())

func _child_removed(_node: Node):
	_redo_tabs.call_deferred(current_tab-1)

func _titles_changed():
	for i in tab_count:
		var tab := _tab_parent.get_child(i)
		set_tab_title(i, tab.title)
	update()

func _redo_tabs(index: int):
	while tab_count:
		remove_tab(0)
	
	for i in _tab_parent.get_child_count():
		var child := _tab_parent.get_child(i)
		add_tab(child.title)
	
	set_current.call_deferred(index)

func set_current(index: int):
	if tab_count == 0:
		current_changed.emit()
	else:
		set_current_tab(clampi(index, 0, tab_count-1))

func _draw() -> void:
	var o := get_tab_offset()
	var fs := get_theme_font_size("font_size")
	
	var last_x := -1.0
	for i in tab_count:
		var r := get_tab_rect(i)
		var t := get_tab_title(i)
		var c := _tab_parent.get_child(i)
		if i < o or r.position.x < last_x:
			c.visible = false
			continue
		last_x = r.position.x
		
		var clr: Color = c.tint
		var out := clr.darkened(.5)
		var cf := clr
		cf.a = 0.5
		var f = font_i if c.is_temporary else font
		if i == current_tab:
			c.visible = true
			draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), clr.darkened(.25))
			draw_string(f if c.is_temporary else font_b, r.position + Vector2(10, 22), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, cf, 6, cf.darkened(.33))
		else:
			c.visible = false
			draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), out.darkened(.25))
			draw_string(f, r.position + Vector2(10, 22), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, clr.darkened(.25), 2, out)
