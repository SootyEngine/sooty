@tool
extends Data
class_name DateTime, "res://addons/sooty_engine/icons/datetime.png"
func get_class() -> String:
	return "DateTime"


#
# Godot's built in Time class starts Months and Weekdays at 1, while this starts at 0.
# So be careful combining the two.
#

var years := 0

var days := 0:
	set(i):
		days = wrapi(i, 0, DAYS_IN_YEAR)
		years += i / DAYS_IN_YEAR

var hours := 0:
	set(i):
		hours = wrapi(i, 0, HOURS_IN_DAY)
		days += i / HOURS_IN_DAY

var minutes := 0:
	set(i):
		minutes = wrapi(i, 0, MINUTES_IN_HOUR)
		hours += i / MINUTES_IN_HOUR

var seconds := 0:
	set(i):
		seconds = wrapi(i, 0, SECONDS_IN_MINUTE)
		minutes += i / SECONDS_IN_MINUTE

func reset():
	years = 0
	days = 0
	hours = 0
	minutes = 0
	seconds = 0

#
# SECONDS
#

func get_total_seconds() -> int:
	return seconds + (minutes * SECONDS_IN_MINUTE) + (hours * SECONDS_IN_HOUR) + (days * SECONDS_IN_DAY) + (years * SECONDS_IN_YEAR)

func set_total_seconds(s: int):
	reset()
	seconds = s
#
# MINUTE
#

func get_total_minutes() -> int:
	return minutes + (hours * MINUTES_IN_HOUR) + (days * MINUTES_IN_DAY) + (years * MINUTES_IN_YEAR)

func goto_next_minute():
	seconds += get_seconds_until_next_minute()

func get_seconds_until_next_minute() -> int:
	return SECONDS_IN_MINUTE - seconds

#
# HOUR
#

func get_total_hours() -> int:
	return hours + (days * HOURS_IN_DAY) + (years * HOURS_IN_YEAR)

func goto_next_hour():
	seconds += get_seconds_until_next_hour()

func get_seconds_until_next_hour() -> int:
	return SECONDS_IN_HOUR - minutes * SECONDS_IN_MINUTE

func is_am() -> bool:
	return get_ampm() == "am"

func get_ampm() -> String:
	return "am" if hours < 12 else "pm"

func set_ampm(s: String):
	s = s.to_lower()
	if s in ["am", "pm"]:
		for i in 12:
			if get_ampm() != s:
				goto_next_hour()
			else:
				break

func get_hour12() -> int:
	return 1 + (hours % 12) * (1 if hours < 12 else -1)

func set_hour12(i: int):
	for i in 12:
		if get_hour12() != i:
			goto_next_hour()
		else:
			break

func is_daytime() -> bool:
	return hours >= 5 and hours <= 16

func set_daytime(d: bool):
	for i in 12:
		if is_daytime() != d:
			goto_next_hour()
		else:
			break

func is_nighttime() -> bool:
	return not is_daytime()

func set_nighttime(b: bool):
	for i in 12:
		if is_nighttime() != b:
			goto_next_hour()
		else:
			break

#
# DAY
#

func get_day_delta() -> float:
	return get_seconds_into_day() / float(SECONDS_IN_DAY)

func is_weekend() -> bool:
	return get_weekday_index() in [WEEKDAY.SATURDAY, WEEKDAY.SUNDAY]

func set_weekend(b):
	for i in 12:
		if is_weekend() != b:
			goto_next_day()
		else:
			break

func get_total_days() -> int:
	return days + (years * DAYS_IN_YEAR)

func goto_next_day():
	seconds += get_seconds_until_next_day()

func get_seconds_into_day() -> int:
	return seconds + (minutes * SECONDS_IN_MINUTE) + (hours * SECONDS_IN_HOUR)

func get_seconds_until_next_day() -> int:
	return SECONDS_IN_DAY - get_seconds_into_day()

func get_days_until(other: Variant) -> int:
	return _to_datetime(other).get_total_days() - get_total_days()

func get_days_until_weekend() -> int:
	var d := get_weekday_index()
	for i in 7:
		if wrapi(d+i, 0, 7) in [WEEKDAY.SATURDAY, WEEKDAY.SUNDAY]:
			return i
	return 7

#
# WEEKDAY
#

func goto_next_week():
	seconds += get_seconds_until_next_week()

func get_seconds_until_next_week() -> int:
	return SECONDS_IN_WEEK - get_seconds_into_week()

func get_seconds_into_week() -> int:
	return get_weekday_index() * SECONDS_IN_DAY

func get_weekday_planet() -> String:
	return PLANET.keys()[get_weekday_index()]

func get_weekday() -> String:
	return WEEKDAY.keys()[get_weekday_index()]

func set_weekday(wd: Variant):
	if wd is int:
		for i in 7:
			if get_weekday_index() != wd:
				goto_next_day()
	elif wd is String:
		wd = wd.to_upper()
		for i in 7:
			if not get_weekday().begins_with(wd):
				goto_next_day()

#func set_weekday_index(wd: int):
#	for i in 7:
#		if get_weekday_index() != wd:
#			goto_next_day()
#		else:
#			break

func get_weekday_index() -> int:
	# zeller's congruence
	var m := get_month_index() - 1
	var y := years
	var d := get_day_of_month()
	
	if m < 1:
		m += 12
		y -= 1
	
	var z = 13 * m - 1
	z = int(z / 5)
	z += d
	z += y
	z += int(y / 4)
	return wrapi(z - 1, 0, 7)

#
# MONTH
#

func _get_month_from_str(s: String) -> int:
	s = s.to_upper()
	for i in 12:
		if MONTH.keys()[i].begins_with(s):
			return i
	return -1

func get_day_of_month() -> int:
	return days - _days_until_month(years, get_month_index()) + 1

func get_day_of_month_ordinal() -> String:
	return UString.ordinal(get_day_of_month())

func set_day_of_month(d: int):
	var y := years
	days = _days_until_month(y, get_month_index()) + d - 1
	years = y

func get_month() -> String:
	return MONTH.keys()[get_month_index()]

func get_month_capitalized() -> String:
	return get_month().capitalize()

func get_month_short() -> String:
	return get_month().substr(0, 3)

func get_month_short_capitalized() -> String:
	return get_month().substr(0, 3).capitalize()

func get_month_index() -> int:
	for i in range(11, -1, -1):
		if days >= _days_until_month(years, i):
			return i
	return -1

func set_month_index(m: int):
	var d := get_day_of_month()
	for i in 12:
		if get_month_index() != m:
			goto_next_month()
	set_day_of_month(d)

func set_month_name(m: String):
	var d := get_day_of_month()
	m = m.to_upper()
	for i in 12:
		if not get_month().begins_with(m):
			goto_next_month()
	set_day_of_month(d)

func set_month(m: Variant):
	if m is int:
		set_month_index(m)
	elif m is String:
		set_month_name(m)

func goto_next_month():
	seconds += get_seconds_until_next_month()

func get_seconds_until_next_month() -> int:
	var m: int = get_month_index()
	var days_until := DAYS_IN_YEAR if m == MONTH.DECEMBER else _days_until_month(years, m+1)
	return (days_until - days) * SECONDS_IN_DAY

func get_months_until(other: Variant) -> int:
	other = _to_datetime(other)
	var dummy: DateTime = duplicate()
	var months := 0
	for i in 12:
		if dummy.month_index != other.month_index:
			months += 1
			dummy.goto_next_month()
		else:
			break
	return months

#
# DATE
#

func get_date() -> String:
	return "%s %s" % [get_month().capitalize(), get_day_of_month()]

func set_date(s: String):
	var p := s.split(" ", false)
	if len(p) > 0:
		set_month(_get_month_from_str(p[0]))
	if len(p) > 1:
		set_day_of_month(p[1].to_int())
	if len(p) > 2:
		years = p[2].to_int()

func get_months_until_date(m:String, _d:int=1) -> int:
	# TODO: Take _d into account.
	var dummy: DateTime = duplicate()
	var months := 0
	var mi = wrapi(_get_month_from_str(m), 0, 12)
	while dummy.get_month_index() != mi:
		dummy.goto_next_month()
		months += 1
	return months

func get_days_until_date(m: String, d := 1) -> int:
	return get_seconds_until_date(m, d) / SECONDS_IN_DAY

func get_seconds_until_date(m: String, d := 1) -> int:
	var dummy: DateTime = duplicate()
	var last_seconds := dummy.get_total_seconds()
	dummy.set_month_index(wrapi(_get_month_from_str(m), 0, 12))
	dummy.set_day_of_month(d)
	return dummy.get_total_seconds() - last_seconds

#
# PERIOD
#

func set_period(p: Variant):
	if p is int:
		for i in len(PERIOD):
			if get_period_index() != p:
				goto_next_period()
	elif p is String:
		p = p.to_upper()
		for i in len(PERIOD):
			if not PERIOD[i].begins_with(p):
				goto_next_period()

func get_period() -> String:
	return PERIOD.keys()[get_period_index()]

func get_period_index() -> int:
	return (wrapi(hours-1, 0, 24) * len(PERIOD)) / 24

func get_seconds_until_next_period() -> int:
	var p := get_period_index()
	var next = SECONDS_IN_PERIOD * (p + 1)
	var curr = SECONDS_IN_PERIOD * p
	return next - curr

func goto_next_period():
	seconds += get_seconds_until_next_period()

#
# SEASONS
#

func goto_next_season():
	seconds += get_seconds_until_next_season()

func get_seconds_until_next_season() -> int:
	var s := get_season_index()
	var next = SECONDS_IN_DAY * DAYS_IN_SEASON * (s + 1)
	return next - SECONDS_IN_DAY * DAYS_IN_SEASON * s

func get_season_index() -> int:
	return wrapi(get_month_index() - 2, 0, 12) / 3

func set_season(s: Variant):
	if s is int:
		for i in len(SEASON):
			if get_season_index() != s:
				goto_next_season()
	elif s is String:
		s = s.to_upper()
		for i in len(SEASON):
			if SEASON.keys()[i] != s:
				goto_next_season()

func get_season() -> String:
	return SEASON.keys()[get_season_index()]

#
# YEAR
#

func get_year() -> int:
	return years

func set_year(y: int):
	years = y

func get_year_delta() -> float:
	return get_seconds_into_year() / float(SECONDS_IN_YEAR)

func get_seconds_into_year() -> int:
	return get_seconds_into_day() + (days * SECONDS_IN_DAY)

func get_seconds_until_next_year() -> int:
	return SECONDS_IN_YEAR - get_seconds_into_year()

func goto_next_year():
	seconds += get_seconds_until_next_year()

#
# FORMAT
#

# TODO:
func format(f := "{year} {month_short_capitalized} {day_of_month_ordinal}") -> String:
	return UString.replace_between(f, "{", "}", _get)

#
# COMPARE
#

func _to_datetime(other: Variant) -> DateTime:
	if other is Dictionary:
		return DateTime.new(other)
	elif other is int:
		return DateTime.new({total_seconds=other})
	else:
		return other

func is_now(other: Variant) -> bool:
	return get_total_seconds() == _to_datetime(other).get_total_seconds()

func is_earlier(other: Variant) -> bool:
	return get_total_seconds() > _to_datetime(other).get_total_seconds()

func is_later(other: Variant) -> bool:
	return get_total_seconds() < _to_datetime(other).get_total_seconds()

func get_relative(other: Variant = null) -> String:
	# base it on current time.
	if other == null:
		other = create_from_current()
	
	var t1 := get_total_seconds()
	var t2 := _to_datetime(other).get_total_seconds()
	if t1 > t2:
		return RELATION.keys()[RELATION.PAST]
	elif t1 < t2:
		return RELATION.keys()[RELATION.FUTURE]
	else:
		return RELATION.keys()[RELATION.PRESENT]

# Time until this DateTime.
func get_until(other: Variant = null) -> String:
	# base it on current time.
	if other == null:
		other = create_from_current()
	
	var r := _get_until(other)
	match r[0]:
		"PRESENT": return "Now"
		"PAST": return "%s %s%s ago" % [r[2], r[1].to_lower(), "" if r[2]==1 else "s"]
		"FUTURE": return "in %s %s%s" % [r[2], r[1].to_lower(), "" if r[2]==1 else "s"]
	push_error("Shouldn't happen.")
	return "???"

# Time since this DateTime.
func get_since(other: Variant = null) -> String:
	if other == null:
		other = create_from_current()
	return other.get_until(self)

# Array: [past or present or future, epoch type (day, month...), total epochs]
func _get_until(other: Variant) -> Array:
	other = _to_datetime(other)
	var t1 := get_total_seconds()
	var t2 = other.get_total_seconds()
	
	# now
	if t1 == t2:
		return [_en(RELATION, RELATION.PRESENT), _en(EPOCH, EPOCH.SECOND), 0]
	
	var rel := _en(RELATION, RELATION.PAST if t2 < t1 else RELATION.FUTURE)
	var dif := absi(t1 - t2)
	for k in EPOCH_SECONDS:
		if dif >= EPOCH_SECONDS[k]:
			return [rel, _en(EPOCH, k), dif / EPOCH_SECONDS[k]]
	
	return ["?", "?", INF]

func _en(e: Variant, i: int) -> String:
	return e.keys()[i]

#
# STATE
#

func get_state() -> Dictionary:
	return { years=years, days=days, hours=hours, minutes=minutes, seconds=seconds }

func set_state(state: Dictionary):
	for k in state:
		if k in self:
			self[k] = state[k]

#
# INTERNAL
#

func _to_string() -> String:
	return "DateTime(years:%s, days:%s, hours:%s, minutes:%s, seconds:%s)" % [years, days, hours, minutes, seconds]

func _get(property: StringName):
	# get_
	var fname := "get_%s" % property
	if has_method(fname):
		return call(fname)
	
	# is_
	fname = "is_%s" % property
	if has_method(fname):
		return call(fname)

func _set(property: StringName, value) -> bool:
	var fname := "set_%s" % property
	if has_method(fname):
		call(fname, value)
		return true
	return false

static func _is_leap_year(y: int) -> bool:
	return y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)

static func _days_until_month(y: int, m: int) -> int:
	return DAYS_UNTIL_MONTH[m] + (1 if m == MONTH.FEBRUARY and _is_leap_year(y) else 0)

static func _days_in_month(y: int, m: int) -> int:
	return 29 if m == MONTH.FEBRUARY and _is_leap_year(y) else DAYS_IN_MONTH[m]

static func create_from_current() -> DateTime:
	return create_from_datetime(Time.get_datetime_dict_from_system())

static func create_from_datetime(d: Dictionary) -> DateTime:
	d.day = d.day - 1 + _days_until_month(d.year, d.month - 1)
	d.hour -= 1
	if "dst" in d and d.dst:
#		var tz = OS.get_time_zone_info()
		var tz = Time.get_time_zone_from_system()
		d.minute = wrapi(d.minute + tz.bias, 0, MINUTES_IN_HOUR)
	
	var out := DateTime.new()
	out.years = d.year
	out.days = d.day
	out.hours = d.hour
	out.minutes = d.minute
	out.seconds = d.second
	return out

static func create_from_total_seconds(s: int) -> DateTime:
	var out := DateTime.new()
	out.total_seconds = s
	return out

static func sort(list: Array, obj_property := "datetime", reverse := false, sort_on := "total_seconds"):
	if reverse:
		list.sort_custom(func(a, b): return a[obj_property][sort_on] > b[obj_property][sort_on])
	else:
		list.sort_custom(func(a, b): return a[obj_property][sort_on] < b[obj_property][sort_on])

func print_all_properties():
	var gets := {}
	var sets := {}
	for m in get_method_list():
		if m.flags & METHOD_FLAG_FROM_SCRIPT != 0:
			if (m.name.begins_with("get_") or m.name.begins_with("is_")) and len(m.args) == 0:
				gets[m.name.split("_", true, 1)[1]] = m
			elif m.name.begins_with("set_") and len(m.args) == 1:
				sets[m.name.split("_", true, 1)[1]] = m
	UDict.sort_by_key(gets)
	UDict.sort_by_key(sets)
	for k in gets:
		if k in sets:
			prints("set get", k)
			sets.erase(k)
		else:
			prints("    get", k)
	for k in sets:
		prints("set    ", k)

const DAYS_IN_YEAR := 365
const DAYS_IN_SEASON := 91
const DAYS_IN_WEEK := 7
const HOURS_IN_DAY := 24
const HOURS_IN_YEAR := HOURS_IN_DAY * 365 # 8_760
const MINUTES_IN_HOUR := 60
const MINUTES_IN_DAY := MINUTES_IN_HOUR * HOURS_IN_DAY # 1_440
const MINUTES_IN_YEAR := MINUTES_IN_DAY * 365 # 525_600
const SECONDS_IN_MINUTE := 60
const SECONDS_IN_HOUR := SECONDS_IN_MINUTE * MINUTES_IN_HOUR # 3_600
const SECONDS_IN_PERIOD := SECONDS_IN_HOUR * 4 # 14_400
const SECONDS_IN_DAY := SECONDS_IN_MINUTE * MINUTES_IN_HOUR * HOURS_IN_DAY # 86_400
const SECONDS_IN_WEEK := SECONDS_IN_DAY * DAYS_IN_WEEK # 604_800
const SECONDS_IN_MONTH := SECONDS_IN_DAY * 30 # 2_592_000
const SECONDS_IN_YEAR := SECONDS_IN_MINUTE * MINUTES_IN_HOUR * HOURS_IN_DAY * DAYS_IN_YEAR # 31_540_000
const SECONDS_IN_DECADE := SECONDS_IN_YEAR * 10
const SECONDS_IN_CENTURY := SECONDS_IN_YEAR * 100

const DAYS_IN_MONTH := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
const DAYS_UNTIL_MONTH := [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]

enum RELATION { PAST, PRESENT, FUTURE }
enum EPOCH { SECOND, MINUTE, HOUR, DAY, WEEK, MONTH, YEAR, DECADE, CENTURY }

const EPOCH_SECONDS := {
	EPOCH.CENTURY: SECONDS_IN_CENTURY,
	EPOCH.DECADE: SECONDS_IN_DECADE,
	EPOCH.YEAR: SECONDS_IN_YEAR,
	EPOCH.MONTH: SECONDS_IN_MONTH,
	EPOCH.WEEK: SECONDS_IN_WEEK,
	EPOCH.DAY: SECONDS_IN_DAY,
	EPOCH.HOUR: SECONDS_IN_HOUR,
	EPOCH.MINUTE: SECONDS_IN_MINUTE,
	EPOCH.SECOND: 1
}

enum WEEKDAY { SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY }
enum MONTH { JANUARY, FEBRUARY, MARCH, APRIL, MAY, JUNE, JULY, AUGUST, SEPTEMBER, OCTOBER, NOVEMBER, DECEMBER }
enum PERIOD { DAWN, MORNING, DAY, DUSK, EVENING, NIGHT }
enum SEASON { SPRING, SUMMER, AUTUMN, WINTER }
enum PLANET { SUN, MOON, MARS, MERCURY, JUPITER, VENUS, SATURN }
enum HOROSCOPE { ARIES, TAURUS, GEMINI, CANCER, LEO, VIRGO, LIBRA, SCORPIUS, SAGITTARIUS, CAPRICORN, AQUARIUS, PISCES, OPHIUCHUS }
enum ANIMAL { RAT, OX, TIGER, RABBIT, DRAGON, SNAKE, HORSE, GOAT, MONKEY, ROOSTER, DOG, PIG }

const UNICODE_ANIMALS := ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
const UNICODE_HOROSCOPE := [0x2648, 0x2649, 0x264A, 0x264B, 0x264C, 0x264D, 0x264E, 0x264F, 0x2650, 0x2651, 0x2652, 0x2653, 0x26CE]
const EMOJI_ANIMALS := ["🐀🐂🐅🐇🐉🐍🐎🐐🐒🐓🐕🐖"] # you wont be able to see these without an emoji font

#
# HOROSCOPE
#

func get_horoscope_unicode() -> String:
	return char(UNICODE_HOROSCOPE[get_horoscope_index()])

func get_horoscope() -> String:
	return HOROSCOPE.keys()[get_horoscope_index()]

func get_horoscope_index() -> int:
	var c := [[9, 19, 10], [10, 18, 11], [11, 20, 0], [0, 19, 1], [1, 20, 2], [2, 20, 3], [3, 22, 4], [4, 22, 5], [5, 22, 6], [6, 22, 7], [7, 21, 8], [8, 21, 9]]
	var h = c[get_month_index()]
	return h[0] if get_day_of_month() <= h[1] else h[2]

#
# ZODIAC
#

func get_zodiac() -> String:
	return ANIMAL.keys()[get_zodiac_index()]

func get_zodiac_unicode() -> String:
	return UNICODE_ANIMALS[get_zodiac_index()]

func get_zodiac_emoji() -> String:
	return EMOJI_ANIMALS[get_zodiac_index()]

func get_zodiac_index() -> int:
	return _z(years - 4)

static func _z(z) -> int:
	return wrapi(z, 0, 12) # int(floor(fposmod(z, 12)))
