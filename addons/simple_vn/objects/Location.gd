extends BaseDataClassExtra
class_name Location

@export var name := ""
@export var parent := ""
@export var format := ""
@export var color := Color.WHITE

func to_string() -> String:
	if format == "":
		if Global.config.has_section_key("default_formats", "location_name"):
			var fmt = Global.config.get_value("default_formats", "location_name", "{name}")
			return fmt.format(UObject.get_state(self))
		else:
			return name
	else:
		return format.format(UObject.get_state(self))
