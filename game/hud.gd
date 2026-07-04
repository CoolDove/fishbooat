extends Control
class_name GameHud

static var instance :GameHud

@onready var boat_state := %boat_state

func _ready():
	instance = self

func set_money(total):
	%money.text = "%s" % total
	%money_animer.play("get_money")

func set_state(text: String, color: Color):
	boat_state.text = text
	boat_state.label_settings.font_color = color
