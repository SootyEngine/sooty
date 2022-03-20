@tool
extends Resource
class_name SpriteTransitions

static func blend(sprite: Sprite2D, next: Texture, tween: Tween):
	if not sprite.is_inside_tree():
		return
		
	var mat := ShaderMaterial.new()
	mat.set_shader(preload("res://simple_vn_assets/shaders/sprite_transition.gdshader"))
	mat.set_shader_param("next", next)
	mat.set_shader_param("blend", 0.0)
	
	if tween:
		tween.stop()
	
	tween = Global.get_tree().create_tween()
	tween.bind_node(sprite)
	tween.tween_callback(sprite.set_material.bind(mat))
	tween.tween_property(mat, "shader_param/blend", 1.0, 1.0).\
		set_trans(Tween.TRANS_CUBIC).\
		set_ease(Tween.EASE_OUT)
	tween.tween_callback(sprite.set_texture.bind(next))
	tween.tween_callback(sprite.set_material.bind(null))
