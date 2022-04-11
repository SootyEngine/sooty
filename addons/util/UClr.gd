@tool
extends RefCounted
class_name UClr

static func sat_shift(color: Color, s := 0.5) -> Color:
	color.s = clampf(color.s + s, 0.0, 1.0)
	return color

static func val_shift(color: Color, v := 0.5) -> Color:
	color.v = clampf(color.v + v, 0.0, 1.0)
	return color

static func hsv_shift(color: Color, h := 0.5, s := 0.0, v := 0) -> Color:
	color.s = clampf(color.s + s, 0.0, 1.0)
	color.v = clampf(color.v + v, 0.0, 1.0)
	color = hue_shift(color, h)
	return color

# @mairod https://gist.github.com/mairod/a75e7b44f68110e1576d77419d608786
# converted to godot by teebar. no credit needed.
const kRGBToYPrime = Vector3(0.299, 0.587, 0.114)
const kRGBToI = Vector3(0.596, -0.275, -0.321)
const kRGBToQ = Vector3(0.212, -0.523, 0.311)
const kYIQToR = Vector3(1.0, 0.956, 0.621)
const kYIQToG = Vector3(1.0, -0.272, -0.647)
const kYIQToB = Vector3(1.0, -1.107, 1.704)

static func hue_shift(color: Color, adjust: float) -> Color:
	var colorv = Vector3(color.r, color.g, color.b)
	var YPrime = colorv.dot(kRGBToYPrime)
	var I = colorv.dot(kRGBToI)
	var Q = colorv.dot(kRGBToQ)
	var hue = atan2(Q, I)
	var chroma = sqrt(I * I + Q * Q)
	hue += adjust * TAU
	Q = chroma * sin(hue)
	I = chroma * cos(hue)
	var yIQ = Vector3(YPrime, I, Q)
	return Color(yIQ.dot(kYIQToR), yIQ.dot(kYIQToG), yIQ.dot(kYIQToB), color.a)
