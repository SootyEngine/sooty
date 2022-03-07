extends CodeEdit
class_name FE_Editor

signal title_changed()
signal tint_changed()

var editors: FE_Editors:
	get: return get_tree().get_first_node_in_group("fe_editors")

var title: String = "":
	set(t):
		title = t
		title_changed.emit()

var tint: Color = Color.DEEP_SKY_BLUE:
	set(t):
		tint = t
		tint_changed.emit()

var is_temporary: bool = true:
	set(t):
		is_temporary = t
		_update_title()

var last_saved_text: String
var file: FE_File

func _init(f: FE_File):
	file = f

func _init_settings():
	draw_tabs = true
	highlight_all_occurrences = true
	highlight_current_line = true
	minimap_draw = true
	scroll_past_end_of_file = true
#	wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	indent_automatic = true
	code_completion_enabled = true
	auto_brace_completion_enabled = true
	auto_brace_completion_highlight_matching = true
	gutters_draw_line_numbers = true
	gutters_draw_fold_gutter = true
	line_folding = true
	
	add_theme_stylebox_override("normal", StyleBoxEmpty.new())
#	add_theme_color_override("background_color", Color.TRANSPARENT)
	
	var m := get_menu()
	m.about_to_popup.connect(_popup_init)
	m.id_pressed.connect(_popup_pressed_id)
#	context_menu_enabled = false

func _popup_init():
	pass

func _popup_pressed_id(id: int):
	pass

func _ready() -> void:
	text = FE_Util.load_text(file.path)
	last_saved_text = text
	
	editors.request.connect(_editor_request)
	text_changed.connect(_text_changed)
	
	_update_word_wrap()
	_update_font_size()
	_init_settings()
	_update_title()
	clear_undo_history()
	add_theme_font_override("font", preload("res://fonts/robotomono/robotomono_r.tres"))
	update_settings()
	
	for node in get_children(true):
		if node is HScrollBar or node is VScrollBar:
			var s: StyleBoxFlat = node.get_theme_stylebox("scroll")
			s.bg_color.a = .125

func _text_changed():
	if is_temporary:
		is_temporary = false
	_update_title()

func _editor_request(r: int):
	match r:
		FE_Editors.R_SAVE:
			if is_unsaved():
				editors.queue_save(file.path, _save_file)
		
		FE_Editors.R_CLOSE_CURRENT:
			if is_current():
				try_close()
			
		FE_Editors.R_SETTINGS_CHANGED:
			_update_word_wrap()
			_update_font_size()
		
		FE_Editors.R_CLOSE_TEMPORARY:
			if is_temporary:
				queue_free()

func _update_word_wrap():
	set_line_wrapping_mode(TextEdit.LINE_WRAPPING_BOUNDARY if editors.word_wrap else TextEdit.LINE_WRAPPING_NONE)

func _update_font_size():
	add_theme_font_size_override("font_size", editors.font_size)

func is_unsaved() -> bool:
	return text != last_saved_text

func is_current() -> bool:
	return editors.current_tab == get_index()

func make_current():
	editors.current_tab = get_index()

func goto(line: int):
	if line != -1:
		set_caret_line(line)
		set_line_as_center_visible(line)

func _save_file():
	if is_unsaved():
		file.save(text)
		last_saved_text = text
		_update_title()

func _save_file_and_close():
	_save_file()
	_close()

func _close():
#	get_parent().remove_child(self)
	queue_free()

func _update_title():
	var t = file.base_name
	if is_unsaved():
		t = "*" + t
	self.title = t

func update_settings():
	pass

func try_close():
	if is_unsaved():
		var d := get_tree().get_first_node_in_group("fe_confirmation_dialog")
		d.setup("There are unedited changes.", _save_file_and_close)
	else:
		_close()

func _get_menu_options() -> Array:
	return []

#func _show_menu():
#	var options := _get_menu_options()
#	if len(options):
#		var popup := OptionsMenu.new()
#		popup.remove_on_hide = true
#		add_child(popup)
#		popup.add_options(options)
#		popup.show()
#		popup.size = Vector2i.ZERO
#		popup.position = get_global_mouse_position()

#func _input(e: InputEvent) -> void:
#	if e is InputEventMouseButton and get_global_rect().has_point(get_global_mouse_position()):
#		prints(get_rect(), e.position)
#		if e.pressed:
#			if e.button_index == MOUSE_BUTTON_RIGHT:
#				_show_menu()
func _shortcut(id: int):
	pass

func _clicked():
	var l := get_caret_line()
	if is_line_folded(l):
		unfold_line(l)
	else:
		fold_line(l)

func _input(e: InputEvent) -> void:
	if e is InputEventMouseButton and not e.pressed and e.ctrl_pressed:
		if get_global_rect().has_point(get_global_mouse_position()):
			_clicked()

func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed:
		if e.ctrl_pressed:
			match e.keycode:
				KEY_SLASH:
					toggle_selection_commented()
					get_viewport().set_input_as_handled()
				
				KEY_1, KEY_2, KEY_3, KEY_4, KEY_5,\
				KEY_6, KEY_7, KEY_8, KEY_9, KEY_0:
					_shortcut(e.keycode - KEY_0)
		
		elif e.alt_pressed:
			match e.keycode:
				KEY_UP:
					move_lines(-1)
					get_viewport().set_input_as_handled()
				KEY_DOWN:
					move_lines(1)
					get_viewport().set_input_as_handled()

func get_comment_head() -> String:
	return "# "

func get_comment_tail() -> String:
	return ""

func _get_selection_for_comment() -> String:
	if has_selection():
		var fl := get_selection_from_line()
		var tl := get_selection_to_line()
		if fl != tl:
			select(fl, 0, tl, len(get_line(tl)))
		else:
			select(fl, get_selection_from_column(), tl, get_selection_to_column())
	else:
		select(get_caret_line(), 0, get_caret_line(), len(get_line(get_caret_line())))
	return get_selected_text()

func _insert_text(t: String):
	begin_complex_operation()
	set_line(get_selection_to_line(), get_line(get_selection_to_line()) + "%R_SPLIT%")
	set_line(get_selection_from_line(), "%L_SPLIT%" + get_line(get_selection_from_line()))
	
	var a := get_text().split("%L_SPLIT%")
	var c := a[1].split("%R_SPLIT%")
	set_text(a[0] + c[0] + t + c[1])
	
	var fl := len(a[0].split("\n"))-1
	var fc := len(a[0].split("\n")[-1])
	var tl := fl + len(c[0].split("\n"))-1
	var tc := len(c[0].split("\n")[-1])
	select(fl, fc, tl, tc)
	set_caret_line(tl)
	set_caret_column(tc)
	
	end_complex_operation()

func is_line_commented(i: int) -> bool:
	return get_line(i).begins_with(get_comment_head())

func set_line_commented(i :int, commented: bool):
	if commented:
		# comment
		if not is_line_commented(i):
			set_line(i, get_comment_head() + get_line(i) + get_comment_tail())
	else:
		# uncomment
		if is_line_commented(i):
			set_line(i, get_line(i).trim_prefix(get_comment_head()).trim_suffix(get_comment_tail()))

func toggle_selection_commented():
	if has_selection():
		var fl := get_selection_from_line()
		var tl := get_selection_to_line()
		var is_commented := true
		
		for i in range(fl, tl+1):
			if not is_line_commented(i):
				is_commented = false
				break
		
		begin_complex_operation()
		for i in range(fl, tl+1):
			set_line_commented(i, not is_commented)
		
		select(fl, 0, tl, len(get_line(tl)))
		
		end_complex_operation()
	else:
		var c := get_caret_line()
		begin_complex_operation()
		set_line_commented(c, not is_line_commented(c))
		select(c, 0, c, len(get_line(c)))
		end_complex_operation()

func move_lines(d: int):
	var l := get_caret_line()
	
	if has_selection():
		var fl := get_selection_from_line()
		var fc := get_selection_from_column()
		var tl := get_selection_to_line()
		var tc := get_selection_to_column()
		if d > 0 and tl + d >= get_line_count():
			return
		if d < 0 and fl + d < 0:
			return
		begin_complex_operation()
		var rng := range(fl, tl+1)
		if d > 0:
			rng.reverse()
		for i in rng:
			swap_lines(i, i+d)
		select(fl+d, fc, tl+d, tc)
		set_caret_line(l+d)
		end_complex_operation()
	
	else:
		begin_complex_operation()
		swap_lines(l, l+d)
		set_caret_line(l+d)
		end_complex_operation()
