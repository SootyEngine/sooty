extends Resource
class_name Markdown

@export var heading_color := Color.WHITE
@export var heading_size := 16
@export var heading_format := "[b;{heading_color};size={heading_size}]{x}[]"

@export var format_bold := "[b]{x}[]"
@export var format_italics := "[i]{x}[]"
@export var format_bold_italics := "[bi]{x}[]"
@export var format_strike_through := "[s]{x}[]"
@export var format_url := "[url]{x}[]"

var x := ""

func parse(text :String) -> String:
	var lines := text.split("\n")
	var out := ""
	
	for i in len(lines):
		# heading
		if lines[i].begins_with("#"):
			x = lines[i].split("# ", true, 1)[1].strip_edges()
			lines[i] = heading_format.format(self)
		
		out += lines[i] + "\n"
	
	return out
