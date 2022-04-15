@tool
extends RefCounted
class_name UClr

#const HUE_SORTED := [24, 137, 139, 31, 142, 114, 134, 115, 40, 11, 143, 42, 7, 46, 50, 55, 127, 123, 67, 64, 92, 118, 133, 32, 16, 100, 70, 122, 121, 117, 15, 119, 107, 108, 78, 6, 29, 12, 130, 1, 94, 8, 106, 93, 99, 141, 96, 43, 23, 49, 18, 48, 58, 62, 102, 26, 5, 144, 75, 97, 57, 66, 98, 145, 28, 52, 14, 61, 33, 138, 25, 44, 51, 77, 76, 103, 53, 68, 120, 85, 128, 91, 87, 81, 3, 135, 71, 88, 4, 104, 20, 22, 2, 35, 131, 65, 36, 13, 111, 63, 39, 124, 72, 129, 0, 41, 126, 73, 74, 17, 116, 9, 95, 90, 21, 47, 59, 82, 125, 34, 86, 84, 113, 10, 56, 112, 30, 37, 83, 140, 27, 136, 132, 110, 45, 79, 101, 89, 38, 54, 80, 60, 105, 19, 109, 69]
const HUE_SORTED := [123, 50, 46, 7, 40, 134, 142, 24, 137, 92, 118, 133, 32, 16, 100, 70, 122, 121, 15, 117, 119, 107, 108, 78, 6, 29, 12, 130, 1, 94, 8, 106, 93, 99, 141, 96, 43, 23, 49, 18, 48, 58, 62, 102, 26, 143, 67, 57, 5, 144, 66, 97, 75, 98, 145, 28, 52, 14, 61, 53, 68, 103, 76, 77, 51, 44, 25, 138, 33, 120, 85, 128, 91, 87, 81, 3, 135, 71, 88, 35, 22, 104, 65, 131, 2, 20, 4, 36, 13, 111, 63, 39, 124, 72, 129, 0, 41, 73, 126, 74, 17, 116, 47, 59, 82, 21, 90, 95, 9, 125, 34, 86, 84, 113, 10, 56, 112, 30, 37, 83, 132, 140, 27, 136, 45, 79, 110, 101, 89, 38, 54, 80, 60, 105, 19, 109, 69, 127, 64, 55, 42, 11, 115, 114, 31, 139]

static func copy_rgb(color: Color, clr2: Color) -> Color:
	color.r = clr2.r
	color.g = clr2.g
	color.b = clr2.b
	return color

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
