extends RigidBody2D
class_name Fish

# 移动参数
@export var pulse_distance = 50.0  # 每次脉冲移动的距离（像素）
@export var pulse_interval = 1.0  # 脉冲间隔（秒）
@export var pulse_force = 200.0  # 脉冲推力

var _pulse_timer = 0.0  # 脉冲计时器

# 移动方向（创建时设置，之后不再改变）
var move_direction = Game.Direction.RIGHT

func _ready():
	_pulse_timer = randf() * 0.4

func set_direction(direction: Game.Direction):
	move_direction = direction
	# 根据方向翻转精灵（只翻转视觉节点，不影响物理）
	if direction == Game.Direction.LEFT:
		$art.scale.x = -1
		%body.scale.x = -1
	else:
		scale = Vector2.ONE  # 向右移动，正常朝向右

func _physics_process(delta):
	# 更新脉冲计时器（追击状态）
	_pulse_timer += delta
	if _pulse_timer >= pulse_interval:
		_apply_pulse()
		_pulse_timer = 0.0

func _apply_pulse():
	# 使用固定的移动方向
	var impulse = Vector2(move_direction * pulse_force, 0)
	apply_central_impulse(impulse)
	# anim_player.play("pulse")
