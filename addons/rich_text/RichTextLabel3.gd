@tool
extends RichTextLabel
class_name RichTextLabel3

const DIR_TEXT_EFFECTS := "res://addons/rich_text/text_effects"
const DIR_TEXT_ANIMATIONS := "res://addons/rich_text/text_animations"
const TAG_OPENED := "["
const TAG_CLOSED := "]"

enum {
	T_NONE,
	T_COLOR, T_OUTLINE_COLOR,
	T_PARAGRAPH,
	T_CONDITION,
	T_BOLD, T_ITALICS, T_BOLD_ITALICS, T_UNDERLINE, T_STRIKE_THROUGH,
	T_CODE,
	T_TABBLE, T_CELL,
	T_EFFECT,
	T_FLAG_CAP, T_FLAG_UPPER, T_FLAG_LOWER
}

enum Align { NONE, LEFT, CENTER, RIGHT }
enum Outline { OFF, DARKEN, LIGHTEN }
enum EffectsMode { OFF, OFF_IN_EDITOR, ON }

@export_multiline var bbcode := "": set = set_bbcode

@export var effects_mode: EffectsMode = EffectsMode.OFF_IN_EDITOR
@export var alignment: Align = Align.CENTER
@export var color: Color = Color.WHITE

@export var outline_mode: Outline = Outline.DARKEN
@export var outline_colored := 0
@export_range(0.0, 1.0) var outline_adjust := 0.5
@export var outline_hue_adjust := 0.0125

@export var nicer_quotes_enabled := true
@export var nicer_quotes_format := "“%s”"

@export var markdown_enabled := true
@export var markdown_format_bold := "[b]%s[]"
@export var markdown_format_italics := "[i]%s[]"
@export var markdown_format_bold_italics := "[bi]%s[]"
@export var markdown_format_strike_through := "[s]%s[]"

var _stack: Array = []
var _state: Dictionary = {}

func _get_tool_buttons():
	return ["_redraw"]

func _ready() -> void:
	_redraw()

func _redraw():
	set_bbcode(bbcode)

func set_bbcode(btext: String):
	text = ""
	bbcode = btext
	clear()
	uninstall_effects()
	
	_stack.clear()
	_state = {
		color = color,
		align = alignment,
		opened = {}
	}
	_parse(_preparse(btext))

func uninstall_effects():
	while len(custom_effects):
		custom_effects.pop_back()

func _preparse(btext :String) -> String:
	# alignment
	match alignment:
		1: btext = "[left]" + btext
		2: btext = "[center]" + btext
		3: btext = "[right]" + btext
	
	# escaped brackets
	btext = btext.replace("\\[", "[lb]")
	btext = btext.replace("\\]", "[rb]")
	
	# nicefy up stuff that isn't tagged.
	btext = _replace_outside(btext, TAG_OPENED, TAG_CLOSED, _preparse_untagged)
	
#	if nicer_quotes_enabled:
#		btext = _replace_between2(btext, '"', '"', func(t): return nicer_quotes_format % t)
	
	return btext

func _preparse_untagged(btext: String) -> String:
	if btext == "":
		return btext
	
	# nice quotes
	if nicer_quotes_format:
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

func _parse(btext :String):
	while TAG_OPENED in btext:
		var p := btext.split(TAG_OPENED, true, 1)
		
		# add head string
		if p[0]:
			_add_text(p[0])
		
		p = p[1].split(TAG_CLOSED, true, 1)
		
		# right side as leftover
		btext = "" if len(p) == 1 else p[1]
		
		# go through all tags
		var tag := p[0]
		
		# close last
		if tag == "":
			# if tags weren't closed, redraw the ending.
			if len(_stack) and not len(_stack[-1]):
				_add_text("[]")
			
			_stack_pop()
		
		# close all
		elif tag == "/":
			while len(_stack):
				_stack_pop()
		
		# close old fashioned way
		elif tag.begins_with("/"):
			pass
#			var _err = append_text("[%s]" % tag)
		
		else:
			_parse_opening(tag)
	
	if btext:
		_add_text(btext)

func _parse_opening(tag: String):
	if tag.begins_with("$"):
		var p := tag.substr(1).split(";", true, 1)
		if len(p) == 2:
			_parse_tags(p[1])
		
		var got = StringAction.execute(p[0])
		if got == null:
			push_error("Couldn't replace '%s'." % p[0])
			push_bgcolor(Color.RED)
			_add_text("[%s]" % tag)
			pop()
		else:
			_add_text(str(got))
		
		if len(p) == 2:
			_stack_pop()
		
	else:
		_parse_tags(tag)

func _parse_tags(tags: String):
	_stack.append([])
	for tag in tags.split(";"):
		_parse_tag(tag)

func _parse_tag(tag: String):
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
		tag_info = tag.substr(b)
	# [tag]
	else:
		tag_name = tag
		tag_info = ""
	
	_parse_tag_info(tag_name, tag_info, tag)

func _passes_condition(cond: String, raw: String) -> bool:
	match cond:
		"if":
			var test := raw.split(" ", true, 1)[1]
			_state.condition = StringAction.test(test)
			_stack_push(T_CONDITION)
			
		"elif":
			prints("ELIF", raw)
			if "condition" in _state and _state.condition == false:
				var test := raw.split(" ", true, 1)[1]
				_state.condition = StringAction.test(test)
				prints("tested:", test, "got:", _state.condition)
		
		"else":
			if "condition" in _state:
				_state.condition = not _state.condition
		
		_:
			if not "condition" in _state or _state.condition == true:
				return true
	
	return false
	
func _parse_tag_info(tag: String, info: String, raw: String):
	if not _passes_condition(tag, raw):
		return
	
	match tag:
		"b": _push_bold()
		"i": _push_italics()
		"bi": _push_bold_italics()
		"s": _push_strikethrough()
		"u": _push_underline()
		
		"left": _push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		"right": _push_paragraph(HORIZONTAL_ALIGNMENT_RIGHT)
		"center": _push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
		"fill": _push_paragraph(HORIZONTAL_ALIGNMENT_FILL)
		
		_:
			if not _has_effect(tag):
				print("no effect ", tag)
			
			# custom effect
			if _has_effect(tag):
				_push_effect(tag, info)
			
			elif not _parse_tag_unused(tag, info, raw):
				append_text("[%s]" % raw)

func _parse_tag_unused(tag: String, _info: String, _raw: String) -> bool:
	# check if it's a color.
	var ci := Color().find_named_color(tag)
	if ci != -1:
		_push_color(Color().get_named_color(ci))
		return true
	
	return false

func _add_text(t :String):
#	if _state.get("condition", true):
	add_text(t)

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

func _push_effect(effect :String, info :String):
	if effects_mode == EffectsMode.OFF:
		return
	
	if effects_mode == EffectsMode.OFF_IN_EDITOR and Engine.is_editor_hint():
		return
	
	_install_effect(effect)
	_stack_push(T_EFFECT, effect)
	append_text(("[%s]" % effect) if info == "" else ("[%s %s]" % [effect, info]))

func _push_color(clr :Color):
	_stack_push(T_COLOR, _state.color)
	_state.color = clr
	push_color(clr)
	
	# outline color
	var outline_color := clr
	match outline_mode:
		Outline.DARKEN: outline_color = clr.darkened(outline_adjust)
		Outline.LIGHTEN: outline_color = clr.lightened(outline_adjust)
	outline_color.h = wrapf(outline_color.h + outline_hue_adjust, 0.0, 1.0)
	push_outline_color(outline_color)
	
	# outline size
	if outline_colored > 0:
		push_outline_size(outline_colored)

func _pop_color(data):
	_state.color = data
	pop()
	if outline_mode != Outline.OFF:
		pop()
	if outline_colored > 0:
		pop()

# remove the last tag or set of tags.
func _stack_pop():
	if len(_stack):
		var last = _stack.pop_back()
		for i in range(len(last)-1, -1, -1):
			var type = last[i][0]
			var data = last[i][1]
			match type:
				T_COLOR: _pop_color(data)
				T_PARAGRAPH: _pop_paragraph(data)
				T_CONDITION: _state.erase("condition")
				T_NONE, _: pop()
			_tag_closed(type, data)

# called when a tag is closed
func _tag_closed(_tag :int, _data :Variant):
	pass

# push a single tag to the last set of tags.
func _stack_push(item :int=-1, data :Variant=null):
	_stack[-1].append([item, data])

func _replace_outside(s: String, head: String, tail: String, fr: Callable) -> String:
	var parts := []
#	var safety := 100
	while true:
#		safety -= 1
#		if safety <= 0:
#			print("tripped safey")
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

# [if name == "Paul"]Hey Paul.[elif name != ""]Hey friend.[else]Who are you?[endif]
func _get_if_chain(s:String) -> Array:
	var p := s.split("]", true, 1)
	var elifs := [Array(p)]
	
	while "[elif " in elifs[-1][-1]:
		p = elifs[-1][-1].split("[elif ", true, 1)
		elifs[-1][-1] = p[0]
		p = p[1].split("]", true, 1)
		elifs.append(Array(p))
	
	if "[else]" in elifs[-1][-1]:
		p = elifs[-1][-1].split("[else]", true, 1)
		elifs[-1][-1] = p[0]
		elifs.append(["true", p[1]])
	
	return elifs
	
#func _replace_conditions(s: String):
#	for test in _get_if_chain(s):
#		if execute_expression(test[0]):
#			return test[1]
#	return ""

#const EXPRESSION_FAILED:String = "%EXPRESSION_FAILED%"
#func execute_expression(e: String, default=EXPRESSION_FAILED):
#	if not context_enabled:
#		return default
#
#	var objs := context
#
#	if not len(objs):
#		if get_tree():
#			objs = [Global, get_tree().current_scene]
#		else:
#			objs = [Global]
#
#	var expression := Expression.new()
#	if expression.parse(e) == OK:
#		var errors := []
#
#		# check each different object
#		for c in objs:
#			var result = expression.execute([], c, false)
#			if expression.has_execute_failed():
#				errors.append(expression.get_error_text())
#			else:
#				return result
#
#		for e in errors:
#			push_error(e)
#
#	return default

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
			# don't install in editor, or there can be bugs
#			if Engine.is_editor_hint():
#				return true

			var effect: RichTextEffect = load(path).new()
			effect.resource_name = id
#			effect.resource_local_to_scene = true
			Global._d[effect] = self
			install_effect(effect)
			return true

	return false
