extends Node2D

const SCALE=.125

var maxim

func continuous_deform(dir):
	var deformationStrength = 1-(clamp(maxim-dir.length(), 0, maxim)/maxim)
	var deformationDirection = Vector2(dir.y, dir.x).normalized()*(1 if dir.x>=0 else -1)
	var deformationScale = SCALE * deformationDirection * deformationStrength
	material.set('shader_parameter/deformation', lerp(material.get('shader_parameter/deformation'), deformationScale, .2))


func burst_deform(dir):
	var deformationStrength = clamp(maxim-dir.length(), 0, maxim)/maxim
	var deformationDirection = Vector2(dir.y, dir.x).normalized()*(1 if dir.x>=0 else -1)
	var deformationScale = SCALE * deformationDirection * deformationStrength
	var tween=create_tween()
	var duration=.2
	tween.tween_property(material, "shader_parameter/deformation",
		deformationScale, duration).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(material, "shader_parameter/deformation",
		Vector2.ZERO, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.play()
