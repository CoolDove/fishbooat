extends Area2D
class_name Bullet

# 物理参数
var velocity = Vector2.ZERO  # 当前速度
var fgravity = 980.0  # 重力加速度（像素/秒^2）
@export var lifetime = 10.0  # 生命周期（秒）
@export var damage = 50.0  # 伤害值
var elapsed_time = 0.0  # 已存在时间

var mount :Node2D

var _captured := false
func capture(mount: Node2D):
	_captured = true
	self.mount = mount

func on_board():
	pass

func _ready():
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.timeout.connect(func():
		if !_captured:
			queue_free()
	)
	add_child(timer)

func _process(delta):
	if _captured:
		global_position = mount.global_position
		return

	velocity.y += fgravity * delta
	position += velocity * delta

	# 可选：旋转子弹朝向运动方向
	rotation = atan2(velocity.y, velocity.x)

# 初始化子弹速度
func initialize(initial_velocity):
	velocity = initial_velocity

# 碰撞检测
func _on_body_entered(body: Node):
	# body 直接就是碰撞体节点
	if body is Monster:
		# 对怪物造成伤害
		body.take_damage(damage)
		# 销毁子弹
		queue_free()
