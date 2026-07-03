extends Node2D
class_name Bullet

# 物理参数
var velocity = Vector2.ZERO  # 当前速度
var gravity = 980.0  # 重力加速度（像素/秒^2）
var lifetime = 10.0  # 生命周期（秒）
var elapsed_time = 0.0  # 已存在时间

func _ready():
	# 启动生命周期计时器
	pass

func _process(delta):
	# 更新生命周期
	elapsed_time += delta
	if elapsed_time >= lifetime:
		queue_free()
		return
	
	# 应用重力
	velocity.y += gravity * delta
	
	# 更新位置
	position += velocity * delta
	
	# 可选：旋转子弹朝向运动方向
	rotation = atan2(velocity.y, velocity.x)

# 初始化子弹速度
func initialize(initial_velocity):
	velocity = initial_velocity
