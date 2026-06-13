extends CharacterBody2D

func _physics_process(_delta):
	print()

	if Input.is_key_pressed(KEY_D):
		velocity.x = 200
	#if Input.is_key_pressed(KEY_A):
		#velocity.x = -200
	#if Input.is_key_pressed(KEY_W):
		#print(Input.is_key_pressed(KEY_D))
#
		#velocity.y = -200
	#if Input.is_key_pressed(KEY_S):
		#print(Input.is_key_pressed(KEY_D))
		#velocity.y = 200
		
	print(position)
	move_and_slide()
