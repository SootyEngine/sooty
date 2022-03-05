extends PopupMenu
class_name OptionsMenu

var _popups := {}
var _options := []
var remove_on_hide := false

func _ready() -> void:
	id_pressed.connect(_option_pressed)
	about_to_popup.connect(_update_checkboxes)

func clear():
	super.clear()
	_popups.clear()
	_options.clear()

func add_options(options: Array):
	for option in options:
		add_option(option)

func add_option(option: Dictionary):
	var id := len(_options)
	_options.append(option)
	
	var text: String = option.get("text", "")
	var popup := _get_popup(text)
	
	if "/" in text:
		text = text.rsplit("/", true, 1)[1]
	
	match option.get("type", "item"):
		"item":
			if "check" in option:
				popup.add_check_item(text, id)
			else:
				popup.add_item(text, id)
		
		"---":
			popup.add_separator(text, id)
	
	if "shortcut" in option:
		popup.set_item_shortcut(popup.get_item_index(id), FE_Util.str_to_shortcut(option.shortcut))
	
	set_process(true)

func _process(delta: float) -> void:
	_update_checkboxes()
	set_process(false)

func _get_popup(full_path: String) -> PopupMenu:
	if not "/" in full_path:
		return self
	
	var split := full_path.rsplit("/", true, 1)
	var popup_id := split[0]
	
	if not popup_id in _popups:
		var popup := PopupMenu.new()
		var split2 := popup_id.rsplit("/", true, 1)
		var popup_name = split2[-1]
		popup.set_name(popup_name)
		popup.id_pressed.connect(_option_pressed)
		popup.about_to_popup.connect(_update_checkboxes)
		_popups[popup_id] = popup
		
		var parent := _get_popup(popup_id)
		parent.add_child(popup)
		parent.add_submenu_item(popup_name, popup_name)
	
	return _popups[popup_id]

func _update_checkboxes():
	for id in len(_options):
		var option: Dictionary = _options[id]
		if "check" in option:
			var popup: PopupMenu = _get_popup(option.text)
			var index := popup.get_item_index(id)
			popup.set_item_checked(index, option.check.call())

func _option_pressed(id: int):
	var index := get_item_index(id)
	if "check" in _options[id]:
		var result = not _options[id].check.call()
		print(_options[id], result)
		_options[id].call.call(result)
	else:
		_options[id].call.call()

func hide():
	super.hide()
	if remove_on_hide:
		queue_free()
