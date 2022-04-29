@tool
extends RichTextLabel
class_name RichTextLabel2

const DIR_TEXT_EFFECTS := "res://addons/rich_text/text_effects"
const DIR_TEXT_ANIMATIONS := "res://addons/rich_text/text_animations"
const TAG_OPENED := "["
const TAG_CLOSED := "]"
const MIN_FONT_SIZE := 8
const MAX_FONT_SIZE := 64

enum {
	T_NONE,
	T_COLOR, T_COLOR_OUTLINE, T_COLOR_BG, T_COLOR_FG,
	T_PARAGRAPH,
	T_CONDITION,
	T_BOLD, T_ITALICS, T_BOLD_ITALICS, T_UNDERLINE, T_STRIKE_THROUGH, T_CODE,
	T_META, T_HINT,
	T_FONT,
	T_FONT_SIZE,
	T_TABBLE, T_CELL,
	T_EFFECT,
	T_PIPE,
	T_FLAG_CAP, T_FLAG_UPPER, T_FLAG_LOWER
}

enum Align { NONE, LEFT, CENTER, RIGHT, FILL }
enum Outline { OFF, DARKEN, LIGHTEN }
enum EffectsMode { OFF, OFF_IN_EDITOR, ON }

signal internal_pressed(variant: Variant)
signal internal_right_pressed(variant: Variant)
signal pressed(variant: Variant)
signal right_pressed(variant: Variant)

@export_multiline var bbcode := "": set = set_bbcode

@export var effects_mode: EffectsMode = EffectsMode.OFF_IN_EDITOR
@export var alignment: Align = Align.CENTER:
	set(x):
		alignment = x
		_redraw()

@export var color := Color.WHITE:
	set(x):
		color = x
		_redraw()
		_update_color()

@export var emoji_scale := 1.0
@export var auto_font := true
@export var font := "":
	set = set_font

@export var font_size: int = 16:
	set(x):
		font_size = clampi(x, MIN_FONT_SIZE, MAX_FONT_SIZE)
		add_theme_font_size_override("bold_font_size", font_size)
		add_theme_font_size_override("bold_italics_font_size", font_size)
		add_theme_font_size_override("italics_font_size", font_size)
		add_theme_font_size_override("mono_font_size", font_size)
		add_theme_font_size_override("normal_font_size", font_size)
		_redraw()

@export var shadow: bool = false:
	set(v):
		shadow = v
		if shadow:
			add_theme_color_override("font_shadow_color", Color(0,0,0,.25))
			add_theme_constant_override("shadow_offset_x", floor(font_size * .08))
			add_theme_constant_override("shadow_offset_y", floor(font_size * .08))
			add_theme_constant_override("shadow_outline_size", ceil(font_size * .1))
			
		else:
			remove_theme_color_override("font_shadow_color")
			remove_theme_constant_override("shadow_offset_x")
			remove_theme_constant_override("shadow_offset_y")
			remove_theme_constant_override("shadow_outline_size")

@export var outline_mode: Outline = Outline.DARKEN:
	set(o):
		outline_mode = o
		_redraw()
		_update_color()
	
@export_range(0.0, 1.0) var outline_adjust := 0.5:
	set(x):
		outline_adjust = x
		_redraw()
		_update_color()
	
@export var outline_hue_adjust := 0.0125:
	set(x):
		outline_hue_adjust = x
		_redraw()
		_update_color()

@export var outline_size := 0:
	set(o):
		outline_size = o
		add_theme_constant_override("outline_size", o)
		_redraw()
		_update_color()

@export var nicer_quotes_enabled := true
@export var nicer_quotes_format := "“%s”"

@export var markdown_enabled := true
@export var markdown_format_bold := "[b]%s[]"
@export var markdown_format_italics := "[i]%s[]"
@export var markdown_format_bold_italics := "[bi]%s[]"
@export var markdown_format_strike_through := "[s]%s[]"

var context: Object # used when request properties or calling pipe functions.

var _stack := []
var _state := {}
var _meta := {}
var _meta_hovered: Variant = null

func _get_tool_buttons():
	return ["_redraw"]

func _init():
	if not Engine.is_editor_hint():
		_connect_meta()

func _connect_meta():
		meta_hover_started.connect(_meta_hover_started)
		meta_hover_ended.connect(_meta_hover_ended)

func _meta_hover_started(meta: Variant):
	_meta_hovered = meta
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _meta_hover_ended(meta: Variant):
	_meta_hovered = null
	mouse_default_cursor_shape = Control.CURSOR_ARROW

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and _meta_hovered != null:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				# call a callable
				if _meta_hovered in _meta:
					if _meta[_meta_hovered] is Callable:
						_meta[_meta_hovered].call()
					elif _meta_hovered.begins_with("_"):
						internal_pressed.emit(_meta[_meta_hovered])
					else:
						pressed.emit(_meta[_meta_hovered])
			
				# goto url
				elif _meta_hovered.begins_with("https://"):
					OS.shell_open(_meta_hovered)
		
				else:
					push_error("No meta url for '%s'. %s" % [_meta_hovered, _meta.keys()])
				
				get_viewport().set_input_as_handled()

			MOUSE_BUTTON_RIGHT:
				if _meta_hovered in _meta:
					if _meta[_meta_hovered] is Callable:
						_meta[_meta_hovered].call()
					elif _meta_hovered.begins_with("_"):
						internal_right_pressed.emit(_meta[_meta_hovered])
					else:
						right_pressed.emit(_meta[_meta_hovered])
				else:
					push_error("No meta url for '%s'." % _meta_hovered)
				get_viewport().set_input_as_handled()

func _update_color():
	add_theme_color_override("font_outline_color", _get_outline_color(color))

var _last_drawn_at := 0
func _redraw():
	if is_inside_tree():
		var frame := get_tree().get_frame()
		if frame == _last_drawn_at:
			print("skip _redraw")
			return
		_last_drawn_at = frame
	set_bbcode(bbcode)

func set_bbcode(btext: String):
	text = ""
	bbcode = btext
	clear()
	uninstall_effects()
	_stack.clear()
	_state = {
		color = color,
		color_bg = null,
		color_fg = null,
		align = alignment,
		font = font,
		font_size = font_size,
		opened = {},
		pipes = []
	}
	if color != Color.WHITE:
		_push_color(color)
	
	_parse(_preparse(btext))
	
	if color != Color.WHITE:
		_pop_color(Color.WHITE)

func set_meta_data(key: String, data: Variant):
	_meta[key] = data

func set_font(id: String):
	font = id
	if auto_font:
		FontHelper.new("res://fonts").set_fonts(self, id)

func uninstall_effects():
	while len(custom_effects):
		custom_effects.pop_back()

func _preparse(btext :String) -> String:
	# alignment
	match alignment:
		1: btext = "[left]%s[]" % btext
		2: btext = "[center]%s[]" % btext
		3: btext = "[right]%s[]" % btext
		4: btext = "[fill]%s[]" % btext
	
	# escaped brackets
	btext = btext.replace("\\[", "[lb]")
	btext = btext.replace("\\]", "[rb]")
	
	# nicefy up stuff that isn't tagged.
	btext = _replace_outside(btext, TAG_OPENED, TAG_CLOSED, _preparse_untagged)
	
	return btext

func _preparse_untagged(btext: String) -> String:
	if btext == "":
		return btext
	
	# nice quotes
	if nicer_quotes_enabled:
		btext = _replace2(btext, '"', nicer_quotes_format)
	
	# markdown
	if markdown_enabled:
		btext = _replace2(btext, "***", markdown_format_bold_italics)
		btext = _replace2(btext, "___", markdown_format_bold_italics)
		btext = _replace2(btext, "**", markdown_format_bold)
		btext = _replace2(btext, "__", markdown_format_bold)
		btext = _replace2(btext, "*", markdown_format_italics)
		btext = _replace2(btext, "_", markdown_format_italics)
		btext = _replace2(btext, "~~", markdown_format_strike_through)
	
	return btext

func _parse(btext: String):
	while TAG_OPENED in btext:
		var p := btext.split(TAG_OPENED, true, 1)
		
		# add head string
		if p[0]:
			_add_text(p[0])
		
		p = p[1].split(TAG_CLOSED, true, 1)
		
		# right side as leftover
		btext = "" if len(p) == 1 else p[1]
		
		# go through all tags
		_parse_tags(p[0])
	
	if btext:
		_add_text(btext)

func _parse_tags(tags_string: String):
	# check for shortcuts
	var p := tags_string.split(";")
	var tags := []
	for i in len(p):
		var tag = p[i]
		if Sooty != null and tag in Sooty.config.rich_text_tags:
			tags.append_array(Sooty.config.rich_text_tags[tag].split(";"))
		else:
			tags.append(tag)
	
	var added_stack := false
	for tag in tags:
		# close last
		if tag == "":
			if added_stack and len(_stack) and not len(_stack[-1]):
				_stack.pop_back()
			if len(_stack) and not len(_stack[-1]):
				_add_text("[]")
			_stack_pop()
			added_stack = false
		
		# close all
		elif tag == "/":
			if added_stack and len(_stack) and not len(_stack[-1]):
				_stack.pop_back()
			while len(_stack):
				_stack_pop()
			added_stack = false
		
		# close old fashioned way
		elif tag.begins_with("/"):
			# TODO
			pass
		
		else:
			if not added_stack:
				added_stack = true
				_stack.append([])
			_parse_tag(tag)
	
	if added_stack and len(_stack) and not len(_stack[-1]):
		_stack.pop_back()

func _parse_tag(tag: String):
	# is a !$^@ StringAction?
	if tag[0] in "~$^@":
		var got = Sooty.actions.do(tag, context)
		# no value was found
		if got == null:
			push_error("BBCode: Couldn't replace '%s'." % tag)
			push_bgcolor(Color.RED)
			_add_text("[%s]" % tag)
			pop()
		else:
			# objects may implement a get_string() method
			_parse(str(got))
		return
		
	# COLOR. This allows doing: "[{color}]Text[]".format({color=Color.RED})
	if UString.is_wrapped(tag, "(", ")"):
		var rgba = UString.unwrap(tag, "(", ")").split_floats(",")
		_push_color(Color(rgba[0], rgba[1], rgba[2], rgba[3]))
		return
	
	# PIPE.
	if tag.begins_with("|"):
		_push_pipe(tag.substr(1))
		return
	
	var tag_name: String
	var tag_info: String
	
	var a = tag.find("=")
	var b = tag.find(" ")
	# [tag=value]
	if a != -1 and (b == -1 or a < b):
		tag_name = tag.substr(0, a)
		tag_info = tag
	# [tag key=val]
	elif b != -1 and (a == -1 or b < a):
		tag_name = tag.substr(0, b)
		tag_info = tag.substr(b).strip_edges()
	# [tag]
	else:
		tag_name = tag
		tag_info = ""
	
	_parse_tag_info(tag_name, tag_info, tag)

func _passes_condition(cond: String, raw: String) -> bool:
	match cond:
		"if":
			var test := raw.split(" ", true, 1)[1]
			_state.condition = Sooty.actions.test(test, context)
			_stack_push(T_CONDITION)
			
		"elif":
			if "condition" in _state and _state.condition == false:
				var test := raw.split(" ", true, 1)[1]
				_state.condition = Sooty.actions.test(test, context)
		
		"else":
			if "condition" in _state:
				_state.condition = not _state.condition
		
		_:
			if not "condition" in _state or _state.condition == true:
				return true
	
	return false

static func has_font(id: String) -> bool:
	return File.new().file_exists("res://fonts/%s.tres" % id)

static func has_emoji_font() -> bool:
	return File.new().file_exists("res://fonts/emoji_font.tres")

static func get_emoji_font() -> Font:
	if has_emoji_font():
		return load("res://fonts/emoji_font.tres")
	return null

func _parse_tag_info(tag: String, info: String, raw: String):
	if not _passes_condition(tag, raw):
		return
	
	# font sizes
	if len(tag) and tag[0].is_valid_int():
		_push_font_size(int(_state.font_size * to_number(tag)))
		return
	
	# emoji: old style
	if tag in Emoji.OLDIE:
		var efont := get_emoji_font()
		if efont != null:
			push_font(efont)
			push_font_size(ceil(_state.font_size * emoji_scale))
			append_text(Emoji.OLDIE[tag])
			pop()
			pop()
		else:
			append_text(Emoji.OLDIE[tag])
		return
	
	# emoji: by name
	if tag.begins_with(":") and tag.ends_with(":"):
		var emoji_name := tag.trim_suffix(":").trim_prefix(":")
		if emoji_name in Emoji.NAMES:
			var efont := get_emoji_font()
			if efont != null:
				push_font(efont)
				push_font_size(ceil(_state.font_size * emoji_scale))
				append_text(Emoji.NAMES[emoji_name])
				pop()
				pop()
			else:
				append_text(Emoji.NAMES[emoji_name])
			return
	
	# is a custom font?
	if has_font(tag):
		_push_font(tag)
		return
	
	match tag:
		"b": _push_bold()
		"i": _push_italics()
		"bi": _push_bold_italics()
		"s": _push_strikethrough()
		"u": _push_underline()
		
		"bg": _push_color_bg(UStringConvert.to_color(info))
		"fg": _push_color_fg(UStringConvert.to_color(info))
		
		"left": _push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		"right": _push_paragraph(HORIZONTAL_ALIGNMENT_RIGHT)
		"center": _push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
		"fill": _push_paragraph(HORIZONTAL_ALIGNMENT_FILL)
		
		"dim": _push_color(_state.color.darkened(.33))
		"dima": _push_color(Color(_state.color.darkened(.33), .5))
		"lit": _push_color(_state.color.lightened(.33))
		"lita": _push_color(Color(_state.color.lightened(.33), .5))
		"hide": _push_color(Color.TRANSPARENT)
		
		# shift the hue. default to 50%.
		"hue": _push_color(UColor.hue_shift(_state.color, to_number(info) if info else 0.5))
		
		"meta": _push_meta(info)
		"hint": _push_hint(info)
		
		"lb": _add_text("[")
		"rb": _add_text("]")
		
		_:
			if not _has_effect(tag):
				pass
			
			# custom effect
			if _has_effect(tag):
				_push_effect(tag, info)
			
			elif not _parse_tag_unused(tag, info, raw):
				append_text("[%s]" % raw)

static func to_number(s: String) -> float:
	if s.is_valid_int():
		return s.to_int() / 100.0
	elif s.is_valid_float():
		return s.to_float()
	else:
		push_warning("Couldn't convert '%s' to number." % [s])
		return 1.0

func _parse_tag_unused(tag: String, _info: String, _raw: String) -> bool:
	# check if it's a color.
	var ci := Color().find_named_color(tag)
	if ci != -1:
		_push_color(Color().get_named_color(ci))
		return true
	
	return false

func _preprocess_pipe(s: String) -> String:
	var i := s.rfind("|")
	if i != -1:
		var input := s.substr(0, i)
		var pipe = s.substr(i+1)
		var args = UString.split_outside(pipe, " ")
		var method = args.pop_front()
		args = args.map(func(x: String): return var2str(UStringConvert.to_var(x)))
		args.push_front(_preprocess_pipe(input))
		return "%s(%s)" % [method, ", ".join(args)]
	return s

func _add_text(t: String):
#	if _state.get("condition", true):
	if len(_state.pipes):
		var piped := t
		for pipe in _state.pipes:
			t += "|" + pipe
		var eval := _preprocess_pipe(t)
		Sooty.actions.eval(eval, context)
		
#		var got = State._pipe(t, pipe)
#		t = str(got)
	add_text(t)

func _push_meta(data: Variant):
	if "^" in data:
		var p = data.split("^", true, 1)
		push_meta(p[0].strip_edges())
		push_hint(p[1].strip_edges())
		_stack_push(T_META)
		_stack_push(T_HINT)
	else:
		push_meta(data.strip_edges())
		_stack_push(T_META)

func _push_hint(data: Variant):
	_stack_push(T_HINT)
	push_hint(data)

func _push_bold():
	_stack_push(T_BOLD)
	push_bold()
	
func _push_italics():
	_stack_push(T_ITALICS)
	push_italics()

func _push_bold_italics():
	_stack_push(T_BOLD_ITALICS)
	push_bold_italics()

func _push_strikethrough():
	_stack_push(T_STRIKE_THROUGH)
	push_strikethrough()

func _push_underline():
	_stack_push(T_UNDERLINE)
	push_underline()

func _push_paragraph(align :int):
	_stack_push(T_PARAGRAPH, _state.align)
	_state.align = align
	push_paragraph(align)

func _pop_paragraph(data):
	_state.align = data
	pop()

func _push_effect(effect: String, info: String):
	if effects_mode == EffectsMode.OFF:
		return
	
	if effects_mode == EffectsMode.OFF_IN_EDITOR and Engine.is_editor_hint():
		return
	
	_install_effect(effect)
	_stack_push(T_EFFECT, effect)
	append_text(("[%s]" % effect) if info == "" else ("[%s %s]" % [effect, info]))

func _push_pipe(pipe: String):
	_stack_push(T_PIPE)
	_state.pipes.append(pipe)

func _pop_pipe():
	_state.pipes.pop_back()

func _push_font(font: String):
	_stack_push(T_FONT, _state.font)
	_state.font = font
	push_font(load("res://fonts/%s.tres" % font))

func _pop_font(last_font):
	_state.font = last_font
	pop()

func _push_font_size(s: int):
	s = clampi(s, MIN_FONT_SIZE, MAX_FONT_SIZE)
	_stack_push(T_FONT_SIZE, _state.font_size)
	_state.font_size = s
	push_font_size(s)

func _pop_font_size(last_size):
	_state.font_size = last_size
	pop()

func _push_color_bg(clr: Color):
	_stack_push(T_COLOR_BG, _state.color_bg)
	_state.color = clr
	push_bgcolor(clr)

func _push_color_fg(clr: Color):
	_stack_push(T_COLOR_FG, _state.color_fg)
	_state.color = clr
	push_bgcolor(clr)

func _push_color(clr: Color):
	_stack_push(T_COLOR, _state.color)
	_state.color = clr
	push_color(clr)
	
	# outline color
	var outline_color := _get_outline_color(clr)
#	match outline_mode:
#		Outline.DARKEN: outline_color = clr.darkened(outline_adjust)
#		Outline.LIGHTEN: outline_color = clr.lightened(outline_adjust)
#	outline_color.h = wrapf(outline_color.h + outline_hue_adjust, 0.0, 1.0)
	push_outline_color(outline_color)
	
	# outline size
	if outline_size > 0:
		push_outline_size(outline_size)

func _get_outline_color(clr: Color) -> Color:
	var out := clr
	match outline_mode:
		Outline.DARKEN: out = clr.darkened(outline_adjust)
		Outline.LIGHTEN: out = clr.lightened(outline_adjust)
	return UColor.hue_shift(out, outline_hue_adjust)
#	out.h = wrapf(out.h + outline_hue_adjust, 0.0, 1.0)
#	return out

func _pop_color(data):
	_state.color = data
	pop()
	if outline_mode != Outline.OFF:
		pop()
	if outline_size > 0:
		pop()

func _pop_color_bg(data):
	_state.color_bg = data
	pop()

func _pop_color_fg(data):
	_state.color_fg = data
	pop()

# remove the last tag or set of tags.
func _stack_pop():
	if len(_stack):
		var last = _stack.pop_back()
		for i in range(len(last)-1, -1, -1):
			var type = last[i][0]
			var data = last[i][1]
			var nopop = last[i][2]
			match type:
				T_COLOR: _pop_color(data)
				T_COLOR_BG: _pop_color_bg(data)
				T_COLOR_FG: _pop_color_fg(data)
				T_PARAGRAPH: _pop_paragraph(data)
				T_PIPE: _pop_pipe()
				T_FONT: _pop_font(data)
				T_FONT_SIZE: _pop_font_size(data)
				T_CONDITION: _state.erase("condition")
				T_NONE, _:
					if not nopop:
						pop()
			_tag_closed(type, data)

# called when a tag is closed
func _tag_closed(_tag: int, _data: Variant):
	pass

# push a single tag to the last set of tags.
func _stack_push(item: int = -1, data: Variant = null, nopop: bool = false):
	if len(_stack):
		_stack[-1].append([item, data, nopop])

func _replace_outside(s: String, head: String, tail: String, fr: Callable) -> String:
	var parts := []
#	var safety := 100
	while true:
#		safety -= 1
#		if safety <= 0:
#			push_error("tripped safey")
#			break
		if head in s:
			var p1 := s.split(head, true, 1)
			if tail in p1[1]:
				var p2 := p1[1].split(tail, true, 1)
				var l := p1[0]
				var m := p2[0]
				var r := p2[1]
				parts.append(str(fr.call(l)))
				parts.append(head + m + tail)
				s = r
			else:
				parts.append(s)
				break
		else:
			break
	
	parts.append(str(fr.call(s)))
	return "".join(parts)

var _replace_index := -1
# call a function on text between a head and tail
func _replace_between(s: String, head: String, tail: String, fr: Callable) -> String:
	_replace_index = 0
	while true:
		_replace_index = s.find(head, _replace_index)
		if _replace_index == -1: break
		var b = s.find(tail, _replace_index+len(head))
		if b == -1: break
		var inner = _part(s, _replace_index+len(head), b)
		if head in inner:
			_replace_index += len(head)
			continue
		var got := str(fr.call(inner))
		if got:
			s = _part(s, 0, _replace_index) + got + _part(s, b+len(tail))
			_replace_index += len(got)
		else:
			s = _part(s, 0, _replace_index) + _part(s, b+len(tail))
	return s

# new version that works regardless of bbcode in the middle.
func _replace2(btext: String, tag: String, format: String):
	var f := format.split("%s", true, 1)
	while tag in btext:
		var p := btext.split(tag, true, 1)
		var o: bool = _state.opened.get(tag, false)
		_state.opened[tag] = not o
		btext = p[0] + (f[1] if o else f[0]) + p[1]
	return btext

# similar to python style substr: s[1:-1]
func _part(s :String, begin: int=0, end=null) -> String:
	if end == null:
		end = len(s)
	
	elif end < 0:
		end = len(s) - end
	
	return s.substr(begin, end-begin)

static func info_to_dict(info:String) -> Dictionary:
	var out:Dictionary = {}
	if "=" in info:
		for part in info.split(" "):
			var kv = part.split("=", true, 1)
			out[kv[0]] = _str2var(kv[1])
	return out

static func _str2var(s: String) -> Variant:
	# allow floats starting with a decimal: .5
	if s.begins_with(".") and s.substr(1).is_valid_int():
		return ("0" + s).to_float()
	return str2var(s)

# [if name == "Paul"]Hey Paul.[elif name != ""]Hey friend.[else]Who are you?[endif]
#func _get_if_chain(s:String) -> Array:
#	var p := s.split("]", true, 1)
#	var elifs := [Array(p)]
#
#	while "[elif " in elifs[-1][-1]:
#		p = elifs[-1][-1].split("[elif ", true, 1)
#		elifs[-1][-1] = p[0]
#		p = p[1].split("]", true, 1)
#		elifs.append(Array(p))
#
#	if "[else]" in elifs[-1][-1]:
#		p = elifs[-1][-1].split("[else]", true, 1)
#		elifs[-1][-1] = p[0]
#		elifs.append(["true", p[1]])
#
#	return elifs

#func _replace_conditions(s: String):
#	for test in _get_if_chain(s):
#		if execute_expression(test[0]):
#			return test[1]
#	return ""

func clear_meta():
	_meta.clear()

func do_clickable(label: String, data: Variant, hint := "", tags := "", is_internal := false) -> String:
	var h = ("_%s" if is_internal else "-%s") % hash(data)
	_meta[h] = data
	if hint:
		if tags:
			return "[meta %s^%s;%s]%s[]" % [h, hint, tags, label]
		else:
			return "[meta %s^%s]%s[]" % [h, hint, label]
	elif tags:
		return "[meta %s;%s]%s[]" % [h, tags, label]
	else:
		return "[meta %s]%s[]" % [h, label]

func _has_effect(id:String) -> bool:
	for e in custom_effects:
		if e.resource_name == id:
			return true
	
	for dir in [DIR_TEXT_EFFECTS, DIR_TEXT_ANIMATIONS]:
		var path = dir.plus_file("RTE_%s.gd" % id)
		if File.new().file_exists(path):
			return true

	return false

func _install_effect(id:String) -> bool:
	# already installed?
	for e in custom_effects:
		if e.resource_name == id:
			return true
	
	for dir in [DIR_TEXT_EFFECTS, DIR_TEXT_ANIMATIONS]:
		var path = dir.plus_file("RTE_%s.gd" % id)
		if File.new().file_exists(path):
			var effect: RichTextEffect = load(path).new()
			effect.resource_name = id
			effect.set_meta("rt", get_instance_id())
			install_effect(effect)
			return true

	return false

static func sanitize(t: String) -> String:
	return UString.replace_between(t, "[", "]", func(s): "").replace("*", "")

#static func colorize_path(path: String, color: Color = Color.DEEP_SKY_BLUE) -> String:
#	var out := "[%s]" % color
#	if "//" in path:
#		var head_tail := path.split("//", true, 1)
#		out += head_tail[0]
#		out += head_tail[1]
#
#	var tail_parts := head_tail[1].split("/")
#	return out + "[]"
