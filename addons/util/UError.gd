@tool
class_name UError

static func warning(error: int, msg: String = "") -> bool:
	if error != OK:
		push_warning("%s (%s)" % [msg, get_type(error)])
		return true
	return false

static func error(error: int, msg: String = "") -> bool:
	if error != OK:
		push_error("%s (%s)" % [msg, get_type(error)])
		return true
	return false

static func get_type(error: int) -> String:
	match error:
		OK: return "Okay"
		FAILED: return "Generic"
		ERR_UNAVAILABLE: return "Unavailable"
		ERR_UNCONFIGURED: return "Unconfigured"
		ERR_UNAUTHORIZED: return "Unauthorized"
		ERR_PARAMETER_RANGE_ERROR: return "Parameter range"
		ERR_OUT_OF_MEMORY: return "Out of memory (OOM)"
		ERR_FILE_NOT_FOUND: return "File: Not found"
		ERR_FILE_BAD_DRIVE: return "File: Bad drive"
		ERR_FILE_BAD_PATH: return "File: Bad path"
		ERR_FILE_NO_PERMISSION: return "File: No permission"
		ERR_FILE_ALREADY_IN_USE: return "File: Already in use"
		ERR_FILE_CANT_OPEN: return "File: Can't open"
		ERR_FILE_CANT_WRITE: return "File: Can't write"
		ERR_FILE_CANT_READ: return "File: Can't read"
		ERR_FILE_UNRECOGNIZED: return "File: Unrecognized"
		ERR_FILE_CORRUPT: return "File: Corrupt"
		ERR_FILE_MISSING_DEPENDENCIES: return "File: Missing dependencies"
		ERR_FILE_EOF: return "File: End of file (EOF)"
		ERR_CANT_OPEN: return "Can't open"
		ERR_CANT_CREATE: return "Can't create"
		ERR_QUERY_FAILED: return "Query failed"
		ERR_ALREADY_IN_USE: return "Already in use"
		ERR_LOCKED: return "Locked"
		ERR_TIMEOUT: return "Timeout"
		ERR_CANT_CONNECT: return "Can't connect"
		ERR_CANT_RESOLVE: return "Can't resolve"
		ERR_CONNECTION_ERROR: return "Connection"
		ERR_CANT_ACQUIRE_RESOURCE: return "Can't acquire resource"
		ERR_CANT_FORK: return "Can't fork process"
		ERR_INVALID_DATA: return "Invalid data"
		ERR_INVALID_PARAMETER: return "Invalid parameter"
		ERR_ALREADY_EXISTS: return "Already exists"
		ERR_DOES_NOT_EXIST: return "Does not exist"
		ERR_DATABASE_CANT_READ: return "Database: Read"
		ERR_DATABASE_CANT_WRITE: return "Database: Write"
		ERR_COMPILATION_FAILED: return "Compilation failed"
		ERR_METHOD_NOT_FOUND: return "Method not found"
		ERR_LINK_FAILED: return "Linking failed"
		ERR_SCRIPT_FAILED: return "Script failed"
		ERR_CYCLIC_LINK: return "Cycling link (import cycle)"
		ERR_INVALID_DECLARATION: return "Invalid declaration"
		ERR_DUPLICATE_SYMBOL: return "Duplicate symbol"
		ERR_PARSE_ERROR: return "Parse"
		ERR_BUSY: return "Busy"
		ERR_SKIP: return "Skip"
		ERR_HELP: return "Help"
		ERR_BUG: return "Bug"
		ERR_PRINTER_ON_FIRE: return "Printer on fire. (This is an easter egg, no engine methods return this error code.)"
		_: return "ERROR %s???" % error
