extends Resource
class_name FontHelper

const DIR := "res://fonts"
const DEFAULT_FONT := ""
const FALLBACK_FONTS := [
	"res://fonts/unifont/unifont-13.0.01.ttf",
	"res://fonts/unifont/unifont_upper-13.0.01.ttf"
]

const PATTERN_R := ["-r", "_r", "-regular", "_regular"]
const PATTERN_B := ["-b", "_b", "-bold", "_bold"]
const PATTERN_I := ["-i", "_i", "-italic", "_italic"]
const PATTERN_BI :=  ["-bi", "_bi", "-bold_italic", "_bold_italic"]
const PATTERN_M := ["-m", "_m", "-mono", "_mono"]

var file := File.new()
var font_cache := {}
var fontset_cache := {}

func _get_font(path: String) -> Font:
	if not path in font_cache:
		if file.file_exists(path):
			var font:Font = Font.new()
			font.add_data(load(path))
			for fallback in FALLBACK_FONTS:
				if file.file_exists(fallback):
					font.add_data(load(fallback))
			font_cache[path] = font
	return font_cache.get(path)

func _find_variant(id: String, tails: Array) -> String:
	
	for restype in [".tres", ".ttf"]:
		for tail in tails:
			var path := DIR.plus_file(id + tail + restype)
			if file.file_exists(path):
				return path
		
		for tail in tails:
			var path := DIR.plus_file(id).plus_file(id + tail + restype)
			if file.file_exists(path):
				return path
	
	return ""

func _get_font_set(head: String) -> Dictionary:
	if not head in fontset_cache:
		fontset_cache[head] = {
			r=_get_font(_find_variant(head, PATTERN_R)),
			b=_get_font(_find_variant(head, PATTERN_B)),
			i=_get_font(_find_variant(head, PATTERN_I)),
			bi=_get_font(_find_variant(head, PATTERN_BI)),
			m=_get_font(_find_variant(head, PATTERN_M)) }
	
	return fontset_cache[head]

func set_fonts(node: Node, fname: String):
	if node is RichTextLabel:
		var rt := node as RichTextLabel
		var f = _get_font_set(fname)
		if f.r:
			node.add_theme_font_override("normal_font", f.r)
			node.add_theme_font_override("bold_font", f.get("b", f.r))
			node.add_theme_font_override("italics_font", f.get("i", f.r))
			node.add_theme_font_override("bold_italics_font", f.get("bi", f.r))
			node.add_theme_font_override("mono_font", f.r if not f.m else f.m)
		
	else:
		var f = _get_font("%s_regular" % [fname])
		node.add_font_override("font", f)
		
		if node is OptionButton:
			node.theme = Theme.new()
			node.theme.default_font = f
#			$OptionButton.theme.default_font.font_data = load("res://your_font_file")
