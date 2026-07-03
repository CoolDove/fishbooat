extends Node2D
class_name Boat


signal bullet_fire(global_direction: Vector2)

# 加农炮参数
@export var cannon_angle_min = 0.0  # 最小角度（度）
@export var cannon_angle_max = 180.0  # 最大角度（度）
@export var bullet_speed = 500.0  # 子弹初速度
@export var cannon_rotation_speed = 3.0  # 炮口旋转速度（弧度/秒）
@export var recoil_force = 2.0  # 后座力强度
var bullet_scene = preload("res://game/boat/bullet.tscn")
var cannon_current_angle = 0.0  # 炮的当前角度（弧度）
var cannon_target_angle = 0.0  # 炮的目标角度（弧度）

# 浮动参数
var float_amplitude = 8.0  # 上下浮动幅度（像素）
var float_speed = 1.5  # 浮动速度
var float_time = 0.0  # 浮动时间累积
var float_velocity = 0.0  # 垂直浮动速度（受冲击影响）
var float_damping = 3.0  # 垂直浮动阻尼
var float_impact_scale = 20.0  # y轴冲击力缩放系数

# 倾斜/晃动参数
var tilt_angle = 0.0  # 当前倾斜角度（弧度）
var tilt_velocity = 0.0  # 倾斜角速度
var tilt_spring_strength = 5.0  # 弹簧恢复力（类似浮力的恢复力矩）
var tilt_damping = 0.6  # 阻尼系数（模拟水的阻力）
var max_tilt = deg_to_rad(50.0)  # 最大倾斜角度

# 海浪参数
var wave_timer = 0.0
var wave_interval_min = 3.0  # 最小海浪间隔
var wave_interval_max = 8.0  # 最大海浪间隔
var next_wave_time = 5.0  # 下次海浪时间
var wave_strength = 0.5  # 海浪冲击强度

# 水平面高度（临时方案，相对于船的初始位置）
var water_level = 0.0
var base_position = Vector2.ZERO

func _ready():
	# 记录初始位置作为基准点
	base_position = position
	# 随机化第一次海浪时间
	randomize()
	next_wave_time = randf_range(wave_interval_min, wave_interval_max)
	
	# 初始化炮的角度
	var cannon = %cannon
	if cannon != null:
		cannon_current_angle = cannon.rotation
		cannon_target_angle = cannon_current_angle

func _process(delta):
	# 更新浮动时间
	float_time += delta * float_speed
	# 计算基础上下浮动
	var float_offset = sin(float_time) * float_amplitude
	# 更新垂直浮动速度（受冲击影响，带阻尼衰减）
	# 使用弹簧阻尼模型，让速度逐渐衰减
	float_velocity -= float_velocity * float_damping * delta
	float_offset += float_velocity
	# 应用浮动到Y轴位置
	position.y = base_position.y + float_offset
	# 海浪系统
	wave_timer += delta
	if wave_timer >= next_wave_time:
		_apply_wave()
		wave_timer = 0.0
		next_wave_time = randf_range(wave_interval_min, wave_interval_max)

	# 更新倾斜角度（阻尼弹簧模型）
	# 恢复力：-spring * angle（类似浮力产生的恢复力矩）
	# 阻尼力：-damping * velocity（类似水的阻力）
	var restore_force = -tilt_angle * tilt_spring_strength
	var damping_force = -tilt_velocity * tilt_damping
	var tilt_acceleration = restore_force + damping_force
	
	tilt_velocity += tilt_acceleration * delta
	tilt_angle += tilt_velocity * delta
	
	# 限制最大倾斜角度
	tilt_angle = clamp(tilt_angle, -max_tilt, max_tilt)
	
	# 应用倾斜
	rotation = tilt_angle
	
	# 更新加农炮瞄准
	_update_cannon_aim()

func _input(event):
	# 检测鼠标左键点击发射
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_fire_cannon()

func _update_cannon_aim():
	# 获取炮节点
	var cannon :Node2D= %cannon
	if cannon == null:
		return
	
	# 计算从炮到鼠标的方向
	var direction := get_global_mouse_position() - cannon.global_position
	var target_deg = rad_to_deg((-transform.x.normalized()).angle_to(direction))
	#if target_deg > -90 and target_deg < 0:
		#target_deg = target_deg
	if target_deg > -180 and target_deg < -90:
		target_deg += 360
	# 限制在可配置的范围内（0度向左，180度向右）
	target_deg = clamp(target_deg, cannon_angle_min, cannon_angle_max)
	
	# 转回弧度
	cannon_target_angle = deg_to_rad(target_deg)
	
	# 计算角度差，处理跨越边界的情况
	var angle_diff = cannon_target_angle - cannon_current_angle
	# 将角度差规范化到 [-PI, PI] 范围，选择最短路径
	while angle_diff > PI:
		angle_diff -= 2.0 * PI
	while angle_diff < -PI:
		angle_diff += 2.0 * PI
	
	# 根据最大旋转速度平滑移动
	var max_rotation_this_frame = cannon_rotation_speed * get_process_delta_time()
	if abs(angle_diff) <= max_rotation_this_frame:
		# 如果差距很小，直接到达目标
		cannon_current_angle = cannon_target_angle
	else:
		# 否则按最大速度旋转
		if angle_diff > 0:
			cannon_current_angle += max_rotation_this_frame
		else:
			cannon_current_angle -= max_rotation_this_frame
	
	# 应用到炮的旋转
	cannon.rotation = cannon_current_angle

func _fire_cannon():
	# 获取炮和子弹生成点
	var cannon = %cannon
	var bullet_spawn = %bullet_spawn
	if cannon == null or bullet_spawn == null:
		return
	
	# 实例化子弹
	var bullet = bullet_scene.instantiate()
	# 添加到场景根节点（而不是船节点，避免受船旋转影响）
	get_tree().root.add_child(bullet)
	# 设置子弹位置为生成点的全局位置
	bullet.global_position = bullet_spawn.global_position
	# 计算子弹发射方向（基于炮的旋转）
	var fire_angle = cannon.global_rotation
	var fire_direction = -Vector2(cos(fire_angle), sin(fire_angle))
	# 初始化子弹速度
	bullet.initialize(fire_direction * bullet_speed)
	# 施加后座力（方向与发射方向相反）
	apply_impact_vector(-fire_direction * recoil_force)
	bullet_fire.emit(fire_direction)

# 海浪冲击（内部使用）
func _apply_wave():
	var wave_direction = randf_range(-1.0, 1.0)
	apply_impact(wave_direction * wave_strength)

# 公开API：施加冲击
# strength: 冲击强度，正值向右倾斜，负值向左倾斜
func apply_impact(strength):
	tilt_velocity += strength

# 公开API：施加冲击（向量版本）
# force: 二维力向量，x分量影响倾斜，y分量影响垂直浮动
func apply_impact_vector(force):
	# x分量影响倾斜
	apply_impact(force.x)
	# y分量影响垂直浮动
	# 正值向下推，负值向上推
	float_velocity += force.y * float_impact_scale

# 公开API：重置船的状态
func reset_boat():
	tilt_angle = 0.0
	tilt_velocity = 0.0
	float_velocity = 0.0
	rotation = 0.0
	position = base_position
