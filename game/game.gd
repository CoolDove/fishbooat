extends Node
class_name Game

var total_money :int
signal get_money(increase: int, total_after_increase: int)

# 移动方向枚举
enum Direction {
	LEFT = -1,
	RIGHT = 1
}

@onready var camera = %camera

@export var water_level := -100.0
@export var camera_shake_strength := 5.0  # 开火时相机抖动强度

# 怪物生成参数
@export var monster_spawn_interval := 5.0  # 怪物生成间隔（秒）
@export var monster_spawn_distance := 700.0  # 生成距离（船两侧的距离）
var _monster_scene = preload("res://monsters/monster.tscn")
var _spawn_timer = 0.0

func _enter_tree():
	%boat.game = self

func _ready():
	# 设置所有怪物的 game 引用
	_setup_monsters()
	# 连接船的 bullet_fire 信号到相机抖动
	%boat.bullet_fire.connect(func(_fire_direction):
		var extra :float= clamp(%boat.impact_fac_with_hp, 0, 1) * 4
		camera.shake_ex(2.5 + extra, 0.3 + %boat.impact_fac_with_hp * 0.2, 1.0)
	)
	%boat.fish_captured.connect(func(fish: Fish):
		print("get money: ", fish.money)
		total_money += fish.money
		get_money.emit(fish.money, total_money)
		var hud := GameHud.instance
		hud.set_money(total_money)
	)
	%boat.hp_changed.connect(func(before:int, after:int):
		if before > after:
			camera.shake_ex(12.0, 0.6, 2.0)
		var hud := GameHud.instance
		print("hp: ", after)
		var percent :float= %boat.hp_percent
		if percent < 0.2:
			hud.set_state("我心永恒~", Color(1,0.2,0.3))
		elif percent < 0.4:
			hud.set_state("船况很差！", Color(0.8,0.6,0.1))
		elif percent < 0.8:
			hud.set_state("船况不妙！", Color(0.6,0.6,0.1))
		elif percent < 0.95:
			hud.set_state("船况良好！", Color(0.5,0.9,0.1))
		else:
			hud.set_state("船况完美！", Color(0.2,1,0.5))
	)

func _process(delta):
	# 更新怪物生成计时器
	_spawn_timer += delta
	if _spawn_timer >= monster_spawn_interval:
		_spawn_monster()
		_spawn_timer = 0.0

# 设置所有怪物的 game 引用
func _setup_monsters():
	for child in get_children():
		if child is Monster:
			child.game = self

# 生成怪物
func _spawn_monster():
	var monster_name :String= load("res://monsters/monsters.tres").pick_random()
	var monster :Node2D= load("res://monsters/%s.tscn" % monster_name).instantiate()
	# var monster = _monster_scene.instantiate()
	add_child(monster)
	
	# 设置 game 引用
	monster.game = self
	
	# 随机选择左侧或右侧生成
	var spawn_on_left = randf() > 0.5
	var boat_x = %boat.global_position.x
	
	if spawn_on_left:
		# 左侧生成，向右移动
		monster.global_position.x = boat_x - monster_spawn_distance
		monster.set_direction(Game.Direction.RIGHT)
	else:
		# 右侧生成，向左移动
		monster.global_position.x = boat_x + monster_spawn_distance
		monster.set_direction(Game.Direction.LEFT)
	
	# 设置 y 坐标到水平线
	monster.global_position.y = water_level
