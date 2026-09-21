extends RichTextLabel

signal stars_increased
signal stars_decreased
signal indicate_insufficiency

const DEFAULT_STAR_SIZE: int = 40
const DEFAULT_FONT_SIZE: int = 42

@export var font_size: float = DEFAULT_FONT_SIZE


enum COLORS {
	NORMAL,
	GREEN,
	RED,
	ORANGE
}

var COLOR_VALUES: Dictionary = {
	COLORS.GREEN: Color("359a34"),
	COLORS.RED: Color("ff0023"),
	COLORS.ORANGE: Color("ff5f00")
}

const SCALE_UP_VALUE: float = 0.4
const SCALE_ANIM_TIME: float = 0.4

var last_star_count: float

@onready var star_image: Texture = preload("res://Collectables/Star/star.svg")

func _ready() -> void:
	last_star_count = DataManager.gameplay.total_stars

	COLOR_VALUES[COLORS.NORMAL] = self.get_theme_color("default_color")

	self.indicate_insufficiency.connect(_scale_up.bind(COLOR_VALUES[COLORS.RED]))
	self.stars_increased.connect(_scale_up.bind(COLOR_VALUES[COLORS.GREEN]))
	self.stars_decreased.connect(_scale_up.bind(COLOR_VALUES[COLORS.ORANGE]))

	self.child_entered_tree.connect(_update_star_count)

	StatManager.star_count_changed.connect(_update_star_count)
	_update_star_count()

func _update_star_count(_change_in_stars = 0):
	var star_scale: float = font_size / DEFAULT_FONT_SIZE

	self.add_theme_color_override("default_color", COLOR_VALUES[COLORS.NORMAL])
	self.clear()

	self.append_text("[center]")

	self.add_image(star_image, roundi(star_scale * DEFAULT_STAR_SIZE), roundi(star_scale * DEFAULT_STAR_SIZE))
	self.add_theme_font_size_override("normal_font_size", roundi(font_size))

	self.append_text(str(DataManager.gameplay.total_stars))

	if last_star_count < DataManager.gameplay.total_stars:
		emit_signal("stars_increased")
	elif last_star_count > DataManager.gameplay.total_stars:
		emit_signal("stars_decreased")

	last_star_count = DataManager.gameplay.total_stars


func _scale_up(color_value: Color = COLOR_VALUES[COLORS.NORMAL]):
	self.add_theme_color_override("default_color", color_value)
	self.pivot_offset = self.size / 2

	var initial_scale: Vector2 = self.scale

	if not self.is_ready():
		await self.ready
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(initial_scale.x + SCALE_UP_VALUE, initial_scale.y + SCALE_UP_VALUE), SCALE_ANIM_TIME/2).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(initial_scale.x, initial_scale.y), SCALE_ANIM_TIME/2).set_trans(Tween.TRANS_CUBIC).set_delay(SCALE_ANIM_TIME/2)
	await tween.finished

	self.add_theme_color_override("default_color", COLOR_VALUES[COLORS.NORMAL])
