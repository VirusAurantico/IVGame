extends KinematicBody2D

const NORMAL = Vector2(0, -1)
var motion = Vector2()
export var GravidadePadrao = 27
var Gravidade = GravidadePadrao
export var Pulo = -600
var impulso = 25
var MaxVelocidade = 300
var Velocidade = 180

var state = 0
var is_sliding = false

func _ready():
	Achievement.secretHat()
	if Achievement.secret == true:
		$SpritePlayer/AnimatedSprite/Hatoid.visible = true
	# Configurar a câmera do jogador para suavidade
	if $Camera2D:
		$Camera2D.smoothing_enabled = true
		$Camera2D.smoothing_speed = 3  # Ajuste a velocidade de suavização conforme necessário

# Função para desativar a suavidade da câmera
func desativar_suavidade_camera():
	if $Camera2D:
		$Camera2D.smoothing_enabled = false

# Função para ativar a suavidade da câmera
func ativar_suavidade_camera():
	if $Camera2D:
		$Camera2D.smoothing_enabled = true
		$Camera2D.smoothing_speed = 3  # Ajuste a velocidade de suavização conforme necessário


func _process(delta):
	states()
	animations()
	_listener(delta)
	is_floor()
	damage()

func _physics_process(_delta):
	altergravity()

func altergravity():
	if Velocidade >= MaxVelocidade:
		Velocidade = MaxVelocidade
	if have_wall() && motion.y > 0 && (Input.is_action_pressed("right") || Input.is_action_pressed("left")):
		Gravidade = 100
		motion.y = Gravidade
	if !have_wall() && !is_on_floor() && Input.is_action_pressed("down"):
		Gravidade = GravidadePadrao*5
		motion.y += Gravidade
	else:
		Gravidade = GravidadePadrao
		motion.y += Gravidade

func is_floor():
	if is_on_floor():
		Global.chao = true
	else:
		Global.chao = false

func states():
	if motion.x == 0 && is_on_floor():
		state = 0 # parado
	if motion.x >= impulso && is_on_floor():
		state = 1 # andando
	elif motion.x <= -impulso && is_on_floor():
		state = 1 # andando
	if !is_on_floor():
		state = 2 # pulou
	if $TimerSlide.time_left or $RayCima.is_colliding():
		state = 3 # deslizando
	if is_on_wall() && is_on_floor() && motion.x == 0 && !$TimerSlide.time_left:
		state = 4 # empurrando
	if !is_on_floor() && have_wall() && Gravidade >= GravidadePadrao:
		state = 5 # deslizando na parede
	if is_on_floor() && motion.x == 0 && Input.is_action_pressed("down"):
		state = 6 # agachando

onready var hat = $SpritePlayer/AnimatedSprite/Hatoid

func secheat():
	if state == 0 or state == 1:
		hat.position = Vector2(0,-9)
	if state == 2 and $SpritePlayer/AnimatedSprite.flip_h == true:
		hat.position = Vector2(-2,-7)
	if state == 2 and $SpritePlayer/AnimatedSprite.flip_h == false:
		hat.position = Vector2(2,-6)
	if state == 3 and $SpritePlayer/AnimatedSprite.flip_h == false:
		hat.position = Vector2(-6,0)
	if state == 3 and $SpritePlayer/AnimatedSprite.flip_h == true:
		hat.position = Vector2(6,0)
	if state == 4 and $SpritePlayer/AnimatedSprite.flip_h == false:
		hat.position = Vector2(6,-7)
	if state == 4 and $SpritePlayer/AnimatedSprite.flip_h == true:
		hat.position = Vector2(-6,-7)
	if state == 5 and $SpritePlayer/AnimatedSprite.flip_h == false:
		hat.position = Vector2(0,-7)
	if state == 5 and $SpritePlayer/AnimatedSprite.flip_h == true:
		hat.position = Vector2(0,-7)
	if state == 6:
		hat.position = Vector2(0,-6)


func animations():
	secheat()
	audio()
	if state == 0:
		$AniPlayer.play("Respirando")
		$SpritePlayer/AnimatedSprite.play("Parado")
		$AnimationPlayer.play("CaixaPadrão")
	elif state == 1:
		$AniPlayer.play("Caminhando")
		$SpritePlayer/AnimatedSprite.play("Andando")
		$AnimationPlayer.play("CaixaPadrão")
	elif state == 2:
		$AniPlayer.play("Saltando")
		$SpritePlayer/AnimatedSprite.play("Pulando")
		$AnimationPlayer.play("CaixaPulo")
	elif state == 3:
		$AniPlayer.play("Escorregando")
		$AnimationPlayer.play("CaixaSlide")
		$SpritePlayer/AnimatedSprite.play("Deslizando")
	elif state == 4:
		$AniPlayer.play("Caminhando")
		$SpritePlayer/AnimatedSprite.play("Empurrando")
		$AnimationPlayer.play("CaixaPadrão")
	elif state == 5:
		$AniPlayer.play("Parede")
		$AnimationPlayer.play("CaixaPulo")
		$SpritePlayer/AnimatedSprite.play("Parede")
	elif state == 6:
		$AniPlayer.play("Respirando")
		$SpritePlayer/AnimatedSprite.play("Agachado")
		$AnimationPlayer.play("CaixaPadrão")


func audio():
	if state == 1 and Velocidade < 200 and invisible == false:
		AudioSFX.Player("grassLow")
	if state == 1 and Velocidade > 200 and invisible == false:
		AudioSFX.Player("grassHigh")
	if Input.is_action_just_pressed("jump") and is_on_floor() or  Input.is_action_just_pressed("jump") and is_on_wall():
		AudioSFX.Player("jump")
	if Input.is_action_just_pressed("down") and is_on_floor():
		AudioSFX.Player("slide")

func _listener(_delta):
	if Global.portal == false:
		if Input.is_action_pressed("right") && !$TimerSlide.time_left:
			move("right")
			$SpritePlayer/AnimatedSprite.flip_h = false
		elif Input.is_action_pressed("left") && !$TimerSlide.time_left:
			move("left")
			$SpritePlayer/AnimatedSprite.flip_h = true
		else:
			move("null")

		if Input.is_action_just_pressed("jump"):
			if is_on_floor():
				move("up")
			elif have_wall():
				walltimer()
		elif Input.is_action_just_released("jump") && !have_wall():
			move("jumpcut")
		if $TimerWallJump.time_left:
			move("walljump")

		if Input.is_action_just_pressed("down") && is_on_floor() && !$TimerSlide.time_left && motion.x != 0 :
			slidetimer()
		if $TimerSlide.time_left && $SpritePlayer/AnimatedSprite.flip_h == false:
			if motion.x != 0:
				Velocidade = Velocidade + impulso
			motion.x = Velocidade
		elif $TimerSlide.time_left && $SpritePlayer/AnimatedSprite.flip_h == true:
			if motion.x != 0:
				Velocidade = Velocidade + impulso
			motion.x = -Velocidade

		if motion.x == 0:
			move("drop")

		if is_sliding && Input.is_action_just_pressed("jump") && !$RayCima.is_colliding():
			cancel_slide_and_jump()

		motion = move_and_slide(motion, NORMAL)

func move(direcao):
	if direcao == "right":
		motion.x = min(motion.x + impulso, Velocidade)
	elif direcao == "left":
		motion.x = max(motion.x - impulso, -Velocidade)
	elif direcao == "up":
		jump()
	elif direcao == "jumpcut":
		jump_cut()
	elif direcao == "walljump":
		wall_jump()
	elif direcao == "slide":
		slide()
	elif direcao == "null":
		motion.x = 0
	elif direcao == "drop":
		Velocidade = 180

func have_wall():
	return $RayDireita.is_colliding() or $RayDireita2.is_colliding() or $RayEsquerda.is_colliding() or $RayEsquerda2.is_colliding()

func wall_jump():
	if ($RayDireita.is_colliding() && $TimerWallJump.time_left) or ($RayDireita2.is_colliding() && $TimerWallJump.time_left):
		motion.y = Pulo
		motion.x = -Velocidade
	elif ($RayEsquerda.is_colliding() && $TimerWallJump.time_left) or ($RayEsquerda2.is_colliding() && $TimerWallJump.time_left):
		motion.y = Pulo
		motion.x = Velocidade

func jump():
	motion.y = Pulo
	if motion.x != 0:
		Velocidade = Velocidade + impulso

func jump_cut():
	if motion.y < -100:
		motion.y = -50

func slide():
	is_sliding = true
	motion.x = Velocidade + impulso
	if motion.x != 0:
		Velocidade = Velocidade + impulso

func slidetimer():
	is_sliding = true
	$TimerSlide.start()

func cancel_slide_and_jump():
	is_sliding = false
	jump()
	$TimerSlide.stop()

func walltimer():
	$TimerWallJump.start()

var invisible = false

func _on_Area2D_area_entered(area):
	if area.is_in_group("Portal"):
		motion.x = 0

func avisar_morte():
	AudioSFX.GUI("death")
	Global.morto()
	Global.add_morte()

func aumentosalto():
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider.is_in_group("Jump"):
			Pulo = -1000
		else:
			Pulo = -600

func damage():
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider.is_in_group("Dano"):
			avisar_morte()

func _on_TimerSlide_timeout():
	if $RayCima.is_colliding():
		$TimerSlide.wait_time = 0.05
		$TimerSlide.start()
	else:
		$TimerSlide.wait_time = 0.5
