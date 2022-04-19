@tool
extends RichTextLabel2
class_name RichTextFoldable

var _fold_state := {}
@export var tag_opened := "[:arrow_right:]"
@export var tag_closed := "[:arrow_down:]"
@export var tag_notab := "[:white_small_square:]"
@export var toggle_by_icon := true
@export var tab_children := true

var filter := ""

func _ready():
	internal_pressed.connect(_pressed)

func _pressed(id: int):
	_fold_state[id] = not _fold_state.get(id, true)
	_redraw()

func _collect(branch: Array, out: Array, deep: int):
	var tabs := "\t".repeat(deep) if tab_children else ""
	if len(branch[1]):
		# use text as hash id
		var line_id := hash(branch[1])
		if not line_id in _fold_state:
			_fold_state[line_id] = true
		var opened: bool = _fold_state.get(line_id, true)
		var tag := tag_opened if opened else tag_closed
		var hint := "Close" if opened else "Open"
		
		# show if passes filter
		if not len(filter) or filter in branch[0]:
			# only allow toggling if it's the icon that was pressed?
			if toggle_by_icon:
				out.append(do_clickable("%s%s" % [tabs, tag], line_id, hint, "b", true) + branch[0])
			else:
				out.append(do_clickable("%s%s%s" % [tabs, tag, branch[0]], line_id, hint, "b", true))
		
		if opened or len(filter):
			for line in branch[1]:
				_collect(line, out, deep + 1)
	
	# show a single line
	# if it's visible, or there is a filter
	else:
		if not len(filter) or filter in branch[0]:
			out.append("%s%s%s" % [tabs, tag_notab, branch[0]])

func _preparse(bbcode: String):
	var tree = UString.get_tabbed_tree(bbcode.replace("\\t", "\t"))
	var out := []
	for branch in tree:
		_collect(branch, out, 0)
	var joined := "\n".join(out)
	return super._preparse(joined)
