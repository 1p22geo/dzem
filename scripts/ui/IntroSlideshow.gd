extends Control

signal intro_finished

const SLIDE_DURATION := 6.0
const FADE_DURATION := 0.8

var slides: Array[Dictionary] = []
var current_slide := -1
var _timer := 0.0
var _fade_timer := 0.0
var _state: String = "idle" # "fade_in", "showing", "fade_out", "done"

@onready var bg: ColorRect = $Background
@onready var slide_image: TextureRect = $SlideImage
@onready var title_label: Label = $TitleLabel
@onready var body_label: RichTextLabel = $BodyLabel
@onready var skip_label: Label = $SkipLabel
@onready var slide_counter: Label = $SlideCounter
@onready var icon_row: HBoxContainer = $IconRow


func _ready() -> void:
	_build_slides()
	modulate = Color.WHITE
	slide_image.modulate = Color.TRANSPARENT
	title_label.modulate = Color.TRANSPARENT
	body_label.modulate = Color.TRANSPARENT
	icon_row.modulate = Color.TRANSPARENT
	_next_slide()


func _build_slides() -> void:
	slides.append({
		"title": "Ryby zmutowały...",
		"body": "Magiczna energia wymknęła się spod kontroli.\nRyby zmutowały i dążą do osiągnięcia pełni mocy\nw świętym zbiorniku wody.",
		"icons": [],
		"bg_color": Color(0.05, 0.08, 0.15, 1.0),
		"title_color": Color(0.9, 0.2, 0.2),
	})

	slides.append({
		"title": "Rybacy próbują ich powstrzymać!",
		"body": "Tylko wykwalifikowani rybacy mogą stanąć na drodze\nzmutowanym rybom i ochronić wioskę.",
		"icons": [],
		"bg_color": Color(0.08, 0.12, 0.06, 1.0),
		"title_color": Color(0.3, 0.9, 0.4),
	})

	slides.append({
		"title": "Trzech bohaterów",
		"body": "[b]Rybak[/b] - rzuca wędką na dystans\n\n[b]Podbierak[/b] - walczy z bliska, atakuje obszarowo\n\n[b]Harpunnik[/b] - powolny ale potężny, ogromny zasięg",
		"icons": ["ranged", "melee", "sniper"],
		"bg_color": Color(0.04, 0.06, 0.14, 1.0),
		"title_color": Color(0.4, 0.7, 1.0),
	})

	slides.append({
		"title": "Słodkowodne ryby",
		"body": "[b]Płotka[/b] - zwykły, słaby przeciwnik\n\n[b]Węgorz[/b] - niezwykle szybki\n\n[b]Sum[/b] - ogromna ryba pełna towarzyszy.\nPo jego śmierci wychodzą z niego płotki i węgorze!",
		"icons": ["plotka", "wegorz", "sum"],
		"bg_color": Color(0.02, 0.08, 0.18, 1.0),
		"title_color": Color(0.3, 0.8, 1.0),
	})

	slides.append({
		"title": "Słonowodne ryby",
		"body": "[b]Dorsz[/b] - opancerzony, trudny do pokonania\n\n[b]Jesiotr[/b] - niezwykle wytrzymały, pożarł kilka dorszy.\nJest za to wolny ale praktycznie niezniszczalny.",
		"icons": ["dorsz", "jesiotr"],
		"bg_color": Color(0.1, 0.04, 0.08, 1.0),
		"title_color": Color(1.0, 0.6, 0.3),
	})

	slides.append({
		"title": "Strategia i magia",
		"body": "Pokonuj ryby aby zarabiać łuski.\nUlepszaj wieże aby stawały się potężniejsze.\n\nUżywaj magii aby osłabić ryby\nale uważaj - magia może się zbuntować\ni oszołomić Twoich rybaków!",
		"icons": [],
		"bg_color": Color(0.1, 0.02, 0.12, 1.0),
		"title_color": Color(0.9, 0.5, 1.0),
	})


func _get_tower_idle_frame(path: String) -> Texture:
	var sheet: Texture2D = load(path)
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var fw := sheet.get_width() / 9.0
	var fh := float(sheet.get_height())
	atlas.region = Rect2(0, 0, fw, fh)
	return atlas


func _get_icon_texture(icon_id: String) -> Texture:
	match icon_id:
		"ranged":
			return _get_tower_idle_frame("res://rangedF.png")
		"melee":
			return _get_tower_idle_frame("res://maleeF.png")
		"sniper":
			return _get_tower_idle_frame("res://sniper.png")
		"plotka":
			return load("res://assets/ryba1-frames/ryba1-frame0000.png")
		"wegorz":
			return load("res://assets/wegorz-frames/wegorz-frame0000.png")
		"sum":
			return load("res://assets/sum-frames/dorsz-framesum-frame0000.png")
		"dorsz":
			return load("res://assets/dorsz-frames/dorsz-frame0000.png")
		"jesiotr":
			return load("res://assets/jesiotr-frames/jesiotr-frame0000.png")
	return null


func _show_slide(index: int) -> void:
	var slide := slides[index]
	title_label.text = slide["title"]
	title_label.add_theme_color_override("font_color", slide["title_color"])
	body_label.text = ""
	body_label.append_text(slide["body"])
	bg.color = slide["bg_color"]
	slide_counter.text = "%d / %d" % [index + 1, slides.size()]

	for child in icon_row.get_children():
		child.queue_free()

	var icons: Array = slide["icons"]
	if icons.size() > 0:
		icon_row.visible = true
		for icon_id in icons:
			var tex := _get_icon_texture(icon_id)
			if tex == null:
				continue
			var rect := TextureRect.new()
			rect.texture = tex
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.custom_minimum_size = Vector2(450, 250)
			icon_row.add_child(rect)
	else:
		icon_row.visible = false


func _next_slide() -> void:
	current_slide += 1
	if current_slide >= slides.size():
		_state = "done"
		_fade_timer = FADE_DURATION
		return

	_show_slide(current_slide)
	_state = "fade_in"
	_fade_timer = FADE_DURATION


func _process(delta: float) -> void:
	if _state == "fade_in":
		_fade_timer -= delta
		var t := clampf(1.0 - (_fade_timer / FADE_DURATION), 0.0, 1.0)
		var alpha := t
		slide_image.modulate = Color(1, 1, 1, alpha)
		title_label.modulate = Color(1, 1, 1, alpha)
		body_label.modulate = Color(1, 1, 1, alpha)
		icon_row.modulate = Color(1, 1, 1, alpha)
		if _fade_timer <= 0.0:
			_state = "showing"
			_timer = SLIDE_DURATION

	elif _state == "showing":
		_timer -= delta
		if _timer <= 0.0:
			_state = "fade_out"
			_fade_timer = FADE_DURATION

	elif _state == "fade_out":
		_fade_timer -= delta
		var t := clampf(1.0 - (_fade_timer / FADE_DURATION), 0.0, 1.0)
		var alpha := 1.0 - t
		slide_image.modulate = Color(1, 1, 1, alpha)
		title_label.modulate = Color(1, 1, 1, alpha)
		body_label.modulate = Color(1, 1, 1, alpha)
		icon_row.modulate = Color(1, 1, 1, alpha)
		if _fade_timer <= 0.0:
			_next_slide()

	elif _state == "done":
		_fade_timer -= delta
		var t := clampf(1.0 - (_fade_timer / FADE_DURATION), 0.0, 1.0)
		modulate = Color(1, 1, 1, 1.0 - t)
		if _fade_timer <= 0.0:
			intro_finished.emit()
			queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if _state == "done":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if _state == "showing":
				_state = "fade_out"
				_fade_timer = FADE_DURATION * 0.4
			elif _state == "fade_in":
				_fade_timer = 0.0
		elif event.keycode == KEY_ESCAPE:
			_state = "done"
			_fade_timer = FADE_DURATION * 0.5

	if event is InputEventMouseButton and event.pressed:
		if _state == "showing":
			_state = "fade_out"
			_fade_timer = FADE_DURATION * 0.4
		elif _state == "fade_in":
			_fade_timer = 0.0
