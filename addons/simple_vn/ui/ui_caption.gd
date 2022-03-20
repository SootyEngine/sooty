@tool
extends Control

@export var shown := false
@export var backing_color := Color(0.0, 0.0, 0.0, 0.25)

@export var _rtl_from: NodePath = ""
@export var _rtl_text: NodePath = ""
@export var _indicator: NodePath = ""
@onready var rtl_from: RichTextLabel2 = get_node(_rtl_from) 
@onready var rtl_text: RichTextAnimation = get_node(_rtl_text) 
@onready var indicator: TextureRect = get_node(_indicator)

# optional choice menu this caption will use
@export var _option_menu: NodePath = ""
@onready var option_menu: Node = get_node(_option_menu)
var _waiting_for_option := false

var _can_skip := true
var _tween: Tween
var _tween_indicator: Tween

var show_indicator := false:
	set = set_show_indicator

func _ready() -> void:
	rtl_from.clear()
	rtl_text.clear()
	rtl_text.faded_in.connect(set_show_indicator.bind(true))
	rtl_text.started.connect(set_show_indicator.bind(false))
	if shown:
		visible = true
		indicator.modulate.a = 1.0
	else:
		visible = false
		indicator.modulate.a = 0.0

func _caption(id: String, msg_type: String, payload: Variant):
#	prints("L %s %s (%s): %s" % [self, id, msg_type, payload])
	if id == "*" or id == name:
		match msg_type:
			"show_line":
				_delay_action()
				
				if not shown:
					shown = true
					visible = true
					var tween := _create_tween()
					tween.tween_property(self, "modulate:a", 1.0, 0.25).from(0.0)
					tween.tween_callback(_show_line.bind(payload))
				else:
					_stop_tween()
					_show_line(payload)
			
			"advance":
				if shown:
					if not _can_skip:
						payload.append(self)
					elif rtl_text.can_advance():
						payload.append(self)
						rtl_text.advance()
						_delay_action()
					elif _waiting_for_option:
						payload.append(self)
					else:
						_hide_eventually()
			
			"hide":
				if shown:
					_hide_eventually()

func _delay_action():
	_can_skip = false
	get_tree().create_timer(0.25).timeout.connect(set.bind("_can_skip", true))

func set_show_indicator(s):
	if show_indicator != s:
		if s and _waiting_for_option:
			return
		show_indicator = s
		if _tween_indicator:
			_tween_indicator.stop()
		_tween_indicator = get_tree().create_tween()
		if s:
			# wait half a second before showing indicator
			_tween_indicator.tween_interval(0.5)
			_tween_indicator.tween_property(indicator, "modulate:a", 1.0, 0.125)
		else:
			_tween_indicator.tween_property(indicator, "modulate:a", 0.0, 0.0125)

func _show_line(payload: Dictionary):
	var from = payload.from
	var line: DialogueLine = payload.line
	var text: String = payload.text
	
	if from is String:
		rtl_from.visible = true
		rtl_from.set_bbcode(from)
		rtl_text.set_bbcode(text)
		rtl_text.fade_out = false
	else:
		rtl_from.visible = false
		rtl_text.set_bbcode(text)
		rtl_text.fade_out = false
	
	# show choices?
	_waiting_for_option = false
	if line.has_options():
		if option_menu:
			option_menu._set_line(line)
			if option_menu.has_options():
				rtl_text.faded_in.connect(option_menu._show_options, CONNECT_ONESHOT)
#				option_menu.selected.connect(_option_selected, CONNECT_ONESHOT)
				_waiting_for_option = true
		else:
			push_error("No options_menu setup %s." % [name])

#func _option_selected(option: DialogueLine):
#	_waiting_for_option = false
#	_hide()
#

func _draw():
	draw_rect(Rect2(Vector2.ZERO, rect_size), backing_color)

# wait a period of time before hiding, in case there will be another text showing up.
func _hide_eventually():
	if shown:
		var tw := _create_tween()
		tw.tween_interval(0.25)
		tw.tween_callback(_hide)

func _hide():
	shown = false
	rtl_text.fade_out = true
	show_indicator = false
	var tw := _create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(set_visible.bind(false))
	return tw

func _stop_tween():
	if _tween:
		_tween.stop()

func _create_tween() -> Tween:
	if _tween:
		_tween.stop()
	_tween = get_tree().create_tween()
	_tween.bind_node(self)
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return _tween
