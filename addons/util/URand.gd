@tool
extends Resource
class_name URand
# lot's of 'noise' and 'fbm' stuff taken from https://github.com/keijiro/

static func set_seed(item: Variant):
	seed(hash(item))

#
# str
#

# chance of vowel in english.
const WEIGHTS_VOWELS_TOTAL:int = 39_400
const WEIGHTS_VOWELS:Dictionary = { e=12_000, a=8_000, i=8_000, o=8_000, u=3_400 }
# chance of consonant in english.
const WEIGHTS_CONSONANTS_TOTAL:int = 67_000
const WEIGHTS_CONSONANTS:Dictionary = { t=9_000, n=8_000, s=8_000, h=6_400, r=6_200, d=4_400, l=4_000, c=3_000, m=3_000, f=2_500, w=2_000, y=2_000, g=1_700, p=1_700, b=1_600, v=1_200, k=800, q=500, j=400, x=400, z=200 }
# change of word length in english.
const WEIGHTS_WORD_LENGTH_TOTAL:int = 28_000
const WEIGHTS_WORD_LENGTH:Dictionary = { 2: 7_000, 3: 8_000, 4: 6_000, 5: 4_000, 6: 3_000 }

static func str_char() -> String: return pick("abcdefghijklmnopqrstuvwxyz0123456789")
static func str_integer() -> String: return pick("123456789")
static func vowel() -> String: return pick_weighted(WEIGHTS_VOWELS, false, WEIGHTS_VOWELS_TOTAL)
static func consonant() -> String: return pick_weighted(WEIGHTS_CONSONANTS, false, WEIGHTS_CONSONANTS_TOTAL)

# ending in a vowel can be useful for female name generation or "latinization".
static func word(length:int=pick_weighted(WEIGHTS_WORD_LENGTH, false, WEIGHTS_WORD_LENGTH_TOTAL), end_in_vowel=rand_bool()) -> String:
	var out := ""
	for i in length:
		if (i % 2 == 0) == end_in_vowel:
			out += vowel()
		else:
			out += consonant()
	return out

static func sentence(length: int = randi_range(3, 5) + lean_low(1, 3)) -> String:
	var out := ""
	for i in length:
		if i == 0:
			out += word().capitalize()
		else:
			if randf() > .99:
				out += pick(":;-")
			elif randf() > .8:
				out += ","
			var wrd = word()
			if len(wrd) > 4 and randf() > .8:
				wrd = wrd.capitalize()
			out += " " + wrd
	return out + pick("......?!")

static func paragraph(length:int=3 + lean_low(2, 4)) -> String:
	var out := ""
	for i in length:
		if i != 0:
			out += " "
		out += sentence()
	return out

#
# bool
#

static func rand_bool() -> bool:
	return randi() % 2 == 0

#
# float
#

static func radian() -> float:
	return randf_range(-PI, PI)

#
# int
#

# takes highest of n rolls.
static func lean_high(samples:int=2, sides:int=100) -> int:
	var best := -(sides+1)
	for i in samples:
		best = maxi(best, randi() % sides)
	return best

# takes lowest of n rolls.
static func lean_low(samples:int=2, sides:int=100) -> int:
	var worst := (sides+1)
	for i in samples:
		worst = mini(worst, randi() % sides)
	return worst

static func pick_lean_high(list:Array, samples:int=2) -> int:
	return list[lean_high(samples, len(list))]

static func pick_lean_low(list:Array, samples:int=2) -> int:
	return list[lean_low(samples, len(list))]

#
# lists
#

# list of random ints that add up to n.
static func list_equaling(n: int = 100, size: int = 20) -> Array:
	var negative = n < 0
	if negative:
		n = -n
	var v = [0, n]
	for i in size-1:
		v.append(0 if n == 0 else randi() % n)
	v.sort()
	var out = []
	for i in range(1, size+1):
		out.append(v[i-1]-v[i] if negative else v[i]-v[i-1])
	return out

# list of random floats that add up to n.
static func list_equalingf(n: float = 1.0, size: int = 20) -> Array:
	var negative = n < 0
	if n < 0:
		n = -n
	var v = [0, n]
	for i in size-1:
		v.append(randf() * n)
	v.sort()
	var out = []
	for i in range(1, size+1):
		out.append(v[i-1]-v[i] if negative else v[i]-v[i-1])
	return out

static func pick(items):# -> Variant:
	return items[randi() % len(items)]

static func pick_excluding(items, item: Variant) -> Variant:
	while true:
		var picked = pick(items)
		if picked != item or len(items) <= 1:
			return picked
	return null

static func pick_excluding_all(items, exclude: Array) -> Variant:
	var safety := 100
	while true:
		var picked = pick(items)
		if not picked in exclude:
			return picked
		safety -= 1
		if safety <= 0:
			push_error("Tripped safety.")
			break
	return null

# picks a random item and removes it from the list or dict.
static func pick_pop(items):
	if items is Dictionary:
		var k = pick(items.keys())
		var out = items[k]
		items.erase(k)
		return out
	elif items is Array:
		var i = randi() % len(items)
		var out = items[i]
		items.remove(i)
		return out
	push_warning("Can't pick_pop %s" % [items])
	return null

# pick a set of items from a list.
static func pick_array(items, count:int) -> Array:
	var out = []
	for i in count:
		out.append(pick(items))
	return out

# pick a distinct set of items from a list.
static func pick_array_unique(items, count:int) -> Array:
	var out = []
	while len(out) < count or len(out) >= len(items):
		var itm = pick(items)
		if not itm in out:
			out.append(itm)
	return out

# keep picking from random lists.
static func pick_recursive(p):
	while true:
		if not p is Array:
			return p
		p = pick(p)

# swap between parents, selecting at that index.
static func pick_genome(parents, r:float=.5) -> Array:
	if parents[0] is String:
		var out = ""
		var parent = pick(parents)
		for i in len(parents[0]):
			if randf() >= r:
				parent = pick(parents)
			out += parent[i]
		return out
	else:
		var out = []
		var parent = pick(parents)
		for i in len(parents[0]):
			if randf() >= r:
				parent = pick(parents)
			out.append(parent[i])
		return out

static func lerp_genome(parents) -> Array:
	var child = []
	for i in len(parents[0]):
		child.append(lerp(parents[0][i], parents[1][i], randf()))
	return child

#
# dict
#

static func _get_dict_weight(d:Dictionary) -> float:
	var total_weight:float = 0.0
	for k in d:
		total_weight += d[k]
	return total_weight

# pass a dict where keys will be returned and values are weights.
static func pick_weighted(d: Dictionary, reverse := false, total_weight=null):
	if total_weight == null:
		total_weight = _get_dict_weight(d)
	var r:float = randf() * total_weight
	if reverse:
		for k in d:
			r -= total_weight - d[k]
			if r <= 0:
				return k
	else:
		for k in d:
			r -= d[k]
			if r <= 0:
				return k

#
# colors
#

static func hash_to_color(item, a:float=1.0) -> Color:
	seed(hash(item))
	return color(1, 1, a)

static func hash_to_float(item) -> float:
	seed(hash(item))
	return randf()

static func _hsv(h, s, v, a=1.0) -> Color: return Color().from_hsv(wrapf(h, 0.0, 1.0), s, v, a)
static func _hue_shift(c:Color, shift:float=.1, s=null, v=null) -> Color:
	return _hsv(c.h + shift, s if s != null else c.s, v if v != null else c.v, c.a)

static func color(s: float = 1.0, v: float = 1.0, a: float = 1.0) -> Color:
	return _hsv(randf(), s, v, a)

static func colors2_complimentary(c: Color = color(), s = null, v = null) -> PackedColorArray:
	return PackedColorArray([c, _hue_shift(c, .5, s, v)])

static func colors3_analogous(c: Color = color(), dist: float = 0.083333) -> PackedColorArray:
	return PackedColorArray([_hue_shift(c, -dist), c, _hue_shift(c, dist)])

static func colors3_triad(c: Color = color()) -> PackedColorArray:
	return PackedColorArray([_hue_shift(c, -0.333333), c , _hue_shift(c, 0.333333)])

static func colors3_split_complement(c: Color = color(), dist: float = 0.083333) -> PackedColorArray:
	return PackedColorArray([c, _hue_shift(c, .5 - dist), _hue_shift(c, .5 + dist)])

static func colors4_square(c: Color = color()) -> PackedColorArray:
	return PackedColorArray([c, _hue_shift(c, .25), _hue_shift(c, .5), _hue_shift(c, .75)])

static func colors4_tetrad(c: Color = color(), dist: float = 0.083333) -> PackedColorArray:
	return PackedColorArray([c, _hue_shift(c, dist), _hue_shift(c, .5), _hue_shift(c, .5 + dist)])

#
# geometry
#

# slow when first called, because it hasn't cached data.
static func in_polygon(poly) -> Vector2:
	# if no cached data, or poly has changed: regenerate.
	if not poly.has_meta("rand_data") or poly.get_meta("rand_data").get("hash") != hash(poly.polygon):
		var points:PackedVector2Array = poly.polygon
		var indices := Geometry2D.triangulate_polygon(points)
		var weights:Dictionary = {}
		for i in range(0, len(indices), 3):
			var a:Vector2 = points[indices[i]]
			var b:Vector2 = points[indices[i+1]]
			var c:Vector2 = points[indices[i+2]]
			var triangle = [a, b, c]
			
			# calculate area
			var aa = a
			var bb = b
			var cc = c
			if poly is Polygon2D or poly is CollisionPolygon2D:
				aa = Vector3(a.x, a.y, 0)
				bb = Vector3(b.x, b.y, 0)
				cc = Vector3(c.x, c.y, 0)
			
			var weight = (aa - bb).cross(bb - cc).length() / 2.0
			
			# area of triangle is it's weight
			weights[triangle] = weight
		
		poly.set_meta("rand_data", {
			weights=weights,
			indices=indices,
			total_weight=_get_dict_weight(weights),
			hash=hash(poly.polygon)
		})
	
	var data = poly.get_meta("rand_data")
	var triangle = pick_weighted(data.weights, data.total_weight)
	return in_triangle(triangle)

static func in_triangle(tri: Array):
	var a := randf()
	var b := randf()
	if  a > b:
		return tri[0] * b + tri[1] * (a - b) + tri[2] * (1.0 - a)
	else:
		return tri[0] * a + tri[1] * (b - a) + tri[2] * (1.0 - b)

#
# vec2
#

static func v2() -> Vector2:
	return Vector2(randf(), randf())

static func in_rect(rect:Rect2) -> Vector2:
	return Vector2(randf_range(rect.position.x, rect.end.x), randf_range(rect.position.y, rect.end.y))

static func on_circle() -> Vector2:
	var r = randf() * TAU
	return Vector2(cos(r), sin(r))

static func in_circle() -> Vector2:
	var r = randf() * TAU
	var l = randf()
	return Vector2(cos(r) * l, sin(r) * l)

#
# vec3
#

static func v3() -> Vector3:
	return Vector3(randf(), randf(), randf())

static func on_sphere() -> Vector3:
	return v3().normalized()

static func in_sphere() -> Vector3:
	return on_sphere() * randf()

#
# aabb
#

static func in_aabb(aabb):
	if aabb is AABB:
		return aabb.position + aabb.size * v3()
	elif aabb.has_method("get_aabb"):
		return aabb.global_transform * in_aabb(aabb.get_aabb())

#
# lerp
#

static func lerp_rand(a, b):
	if a is Vector3:
		return Vector3(lerp(a.x, b.x, randf()), lerp(a.y, b.y, randf()), lerp(a.z, b.z, randf()))
	elif a is Vector2:
		return Vector2(lerp(a.x, b.x, randf()), lerp(a.y, b.y, randf()))
	elif a is Color:
		return _hsv(lerp(a.h, b.h, randf()), lerp(a.s, b.s, randf()), lerp(a.v, b.v, randf()), lerp(a.a, b.a, randf()))
	else:
		return lerp(a, b, randf())

#
# noise
#

const TIME_SCALE:float = 1.0 / 120.0
static func _time(time_scale:float) -> float:
	return Time.get_ticks_msec() * TIME_SCALE * time_scale

# about -0.5 - 0.5
static func noise(x: float) -> float:
	var X = _floori(x) & 0xff
	x -= floor(x)
	return lerp(_grad(_perm[X], x), _grad(_perm[X+1.0], x-1.0), _fade(x))

static func noise_animated(s := 0.125, time_scale := 1.0) -> float:
	return noise(s + _time(time_scale))

static func noise_animated_lerp(a, b, s := 0.0, time_scale := 1.0) -> float:
	return lerp(a, b, noise_animated(s, time_scale) + .5)

static func noise_v2(s: Vector2) -> Vector2:
	return Vector2(noise(s.x), noise(s.y))

static func noise_v3(s: Vector3) -> Vector3:
	return Vector3(noise(s.x), noise(s.y), noise(s.z))

static func noise_animated_v2(s: Vector2 = Vector2(1,2), time_scale: float = 1.0) -> Vector2:
	return noise_v2(s + Vector2.ONE * _time(time_scale))

static func noise_animated_v3(s: Vector3 = Vector3(1,2,3), time_scale: float = 1.0) -> Vector3:
	return noise_v3(s + Vector3.ONE * _time(time_scale))

#
# fractal brownian motion
#

# -0.5 - 0.5
static func fbm(x:float=OS.get_system_time_msecs() * TIME_SCALE, octaves:int=2) -> float:
	var total:float = 0.0 		# final result
	var amplitude:float = 1.0	# amplitude
	var maximum:float = 0.0		# maximum
	var e:float = 3.0
	for i in octaves:
		total += amplitude * noise(x)
		maximum += amplitude
		amplitude *= 0.5
		x *= e
		e *= .95
	return total / maximum

static func fbm_animated(s:float=0.0, time_scale:float=1.0, octaves:int=2) -> float:
	return fbm(s + _time(time_scale), octaves)

static func fbm_animated_lerp(a, b, s:float=0.0, time_scale:float=1.0, octaves:int=2) -> float:
	return lerp(a, b, fbm_animated(s, octaves, time_scale) + .5)

static func fbm_v2(s:Vector2, octaves:int=2) -> Vector2:
	return Vector2(fbm(s.x, octaves), fbm(s.y, octaves))

static func fbm_v3(s:Vector3, octaves:int=2) -> Vector3:
	return Vector3(fbm(s.x, octaves), fbm(s.y, octaves), fbm(s.z, octaves))

static func fbm_animated_v2(s := Vector2(1,2), time_scale := 1.0, octaves := 2) -> Vector2:
	var t = _time(time_scale)
	return fbm_v2(s + Vector2(t, -t), octaves)

static func fbm_animated_v3(s := Vector3(1,2,3), time_scale := 1.0, octaves := 2) -> Vector3:
	return fbm_v3(s + Vector3.ONE * _time(time_scale), octaves)

static func _noise2(x:float, y:float) -> float:
	var X = _floori(x) & 0xff
	var Y = _floori(y) & 0xff
	x -= floor(x)
	y -= floor(y)
	var u = _fade(x)
	var v = _fade(y)
	var A = (_perm[X] + Y) & 0xff
	var B = (_perm[X+1] + Y) & 0xff
	return lerp(lerp(_grad2(_perm[A], x, y),	_grad2(_perm[B], x-1, y), u),
				lerp(_grad2(_perm[A+1], x, y-1), _grad2(_perm[B+1], x-1, y-1), u), v)

static func _noise3(x:float, y:float, z:float) -> float:
	var X = _floori(x) & 0xff
	var Y = _floori(y) & 0xff
	var Z = _floori(z) & 0xff
	x -= _floori(x)
	y -= _floori(y)
	z -= _floori(z)
	var u = _fade(x)
	var v = _fade(y)
	var w = _fade(z)
	var A  = (_perm[X] + Y) & 0xff
	var B  = (_perm[X+1] + Y) & 0xff
	var AA = (_perm[A] + Z) & 0xff
	var BA = (_perm[B] + Z) & 0xff
	var AB = (_perm[A+1] + Z) & 0xff
	var BB = (_perm[B+1] + Z) & 0xff
	return lerp(lerp(lerp(_grad3(_perm[AA], x, y, z), _grad3(_perm[BA], x-1, y, z), u),
					lerp(_grad3(_perm[AB], x, y-1, z), _grad3(_perm[BB], x-1, y-1, z), u), v),
				lerp(lerp(_grad3(_perm[AA+1], x, y, z-1), _grad3(_perm[BA+1], x-1, y, z-1), u),
					lerp(_grad3(_perm[AB+1], x, y-1, z-1), _grad3(_perm[BB+1], x-1, y-1, z-1), u), v), w)

static func _fbm2(x:float, y:float, octave:int=2) -> float:
	var total:float = 0.0
	var amplitude:float = 0.5
	var maximum:float = 0.0
	var e:float = 3.0
	for i in octave:
		total += amplitude * _noise2(x, y)
		maximum += amplitude
		amplitude *= 0.5
		x *= e
		y *= e
		e *= .95
	return total / maximum

static func _fbm3(x:float, y:float, z:float, octave:int=2) -> float:
	var total:float = 0.0
	var amplitude:float = 0.5
	var maximum:float = 0.0
	var e:float = 3.0
	for i in octave:
		total += amplitude * _noise3(x, y, z)
		maximum += amplitude
		amplitude *= 0.5
		x *= e
		y *= e
		z *= e
		e *= .95
	return total / maximum

static func _floori(x:float) -> int:
	return int(floor(x))

static func _fade(t:float) -> float:
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)

static func _grad(h:int, x:float) -> float:
	return x if (h & 1) == 0 else -x

static func _grad2(h:int, x:float, y:float) -> float:
	return (x if (h & 1) == 0 else -x) + (y if (h & 2) == 0 else -y)

static func _grad3(h:int, x:float, y:float, z:float) -> float:
	h = h & 15;
	var u = x if h < 8 else y
	var v = y if h < 4 else (x if h == 12 || h == 14 else z)
	return (u if (h & 1) == 0 else -u) + (v if (h & 2) == 0 else -v)

const _perm:Array = [
151,160,137,91,90,15,
131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
151]
