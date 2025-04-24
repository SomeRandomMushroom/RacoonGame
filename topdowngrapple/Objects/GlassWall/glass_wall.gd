extends StaticBody2D

func destroy():
	AudioManager.create_2d_audio_at_location(position, SoundEffect.SOUND_EFFECT_TYPE.GLASSBREAK)
	queue_free()
