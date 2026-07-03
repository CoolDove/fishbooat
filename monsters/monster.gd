extends RigidBody2D
class_name Monster

# 移动参数
@export var pulse_distance = 50.0  # 每次脉冲移动的距离（像素）
@export var pulse_interval = 1.0  # 脉冲间隔（秒）
@export var pulse_force = 200.0  # 脉冲推力

# 攻击参数
@export var retreat_force = 200.0  # 后撤力度
@export var charge_force = 1500.0  # 冲撞力度
@export var charge_impact_force = 5.0  # 冲撞对船的冲击力

# 生命值
@export var max_health = 100.0  # 最大生命值
var _current_health = 100.0  # 当前生命值

# 引用
var game: Game
var _boat: Node = null

# 内部状态
var _is_attacking = false  # 是否正在攻击
var _is_dead = false  # 是否已死亡
var _pulse_timer = 0.0  # 脉冲计时器

@onready var anim_player = %AnimationPlayer

func _ready():
	# 初始化生命值
	_current_health = max_health
	
	# 设置 RigidBody2D 属性
	gravity_scale = 0.0  # 禁用重力
	lock_rotation = true  # 锁定旋转
	linear_damp = 2.0  # 添加线性阻尼
	
	# 设置初始位置到水平线
	if game != null:
		global_position.y = game.water_level
	
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	
	# 连接攻击范围信号
	%attack_range.body_entered.connect(_on_attack_range_body_entered)
	
	print("Monster ready, mass: ", mass, " gravity_scale: ", gravity_scale)

func _physics_process(delta):
	# 更新脉冲计时器（追击状态）
	if not _is_attacking:
		_pulse_timer += delta
		if _pulse_timer >= pulse_interval:
			_apply_pulse()
			_pulse_timer = 0.0

func _integrate_forces(state: PhysicsDirectBodyState2D):
	# 锁定 y 轴位置到水平线
	if game != null:
		state.transform.origin.y = game.water_level
	
	# 只保留 x 轴速度
	state.linear_velocity.y = 0

# 施加一次脉冲推力
func _apply_pulse():
	# 向船的方向施加冲量
	var direction = 1.0  # 默认向右
	if _boat != null:
		direction = sign(_boat.global_position.x - global_position.x)
	
	var impulse = Vector2(direction * pulse_force, 0)
	apply_central_impulse(impulse)
	anim_player.play("pulse")

# 攻击范围检测
func _on_attack_range_body_entered(body: Node2D):
	# body 直接就是碰撞体节点，不需要 get_parent
	if body is Boat and not _is_attacking:
		_boat = body
		_perform_attack()

# 与船碰撞检测
func _on_body_entered(body: Node):
	# body 直接就是碰撞体节点，不需要 get_parent
	if body is Boat:
		# 施加冲击到船
		if body.has_method("apply_impact_vector"):
			var direction = sign(linear_velocity.x)
			body.apply_impact_vector(Vector2(direction * charge_impact_force, 0))
		
		# 消失
		_disappear()

# 发动攻击（后撤 -> 冲撞）
func _perform_attack():
	_is_attacking = true
	
	# 清除当前速度
	linear_velocity = Vector2.ZERO
	
	# 1. 后撤阶段
	var retreat_direction = -sign(_boat.global_position.x - global_position.x)
	apply_central_impulse(Vector2(retreat_direction * retreat_force, 0))
	
	# 等待后撤完成（速度降低）
	await get_tree().create_timer(0.5).timeout
	anim_player.play("pulse")

	# 2. 冲撞阶段
	linear_velocity = Vector2.ZERO  # 清除速度
	var charge_direction = sign(_boat.global_position.x - global_position.x)
	apply_central_impulse(Vector2(charge_direction * charge_force, 0))
	
	_boat.apply_impact(1)
	await get_tree().create_timer(0.5).timeout
	_disappear()

# 受到伤害
func take_damage(damage: float):
	if _is_dead:
		return
	_current_health -= damage
	print("Monster took ", damage, " damage, health: ", _current_health, "/", max_health)
	anim_player.play("hurt")
	if _current_health <= 0:
		_die()

# 死亡
func _die():
	if _is_dead:
		return
	
	_is_dead = true
	_is_attacking = false
	
	# 停止所有物理运动
	set_deferred("freeze", true)
	
	# 播放消失动画并销毁
	_disappear()

# 播放消失动画并销毁
func _disappear():
	# 停止所有物理运动
	set_deferred("freeze", true)
	anim_player.play("disapear")
	await anim_player.animation_finished
	queue_free()
