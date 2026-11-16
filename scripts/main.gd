extends Node3D
## I01 playable prototype. Keyboard only in this increment.
## Physical state lives in VehicleSimulator; meshes/camera are presentation only.

const VehicleSimulator = preload("res://scripts/simulation/vehicle_simulator.gd")
const VehicleConfig = preload("res://scripts/simulation/vehicle_config.gd")
const RaceSession = preload("res://scripts/race/race_session.gd")
const TrackBuilder = preload("res://scripts/visuals/track_builder.gd")
const VehicleBuilder = preload("res://scripts/visuals/vehicle_builder.gd")

var config: NoPrepVehicleConfig
var car_sim: NoPrepVehicleSimulator
var race: NoPrepRaceSession
var car: Node3D
var chase_camera: Camera3D
var tree: Dictionary
var input_throttle: float = 0.0
var input_steer: float = 0.0
var elapsed_visual_s: float = 0.0
var status_label: Label
var stats_label: Label
var tune_label: Label
var speed_label: Label
var speed_sub_label: Label
var countdown_label: Label
var footer_label: Label

func _ready() -> void:
	config = VehicleConfig.new()
	car_sim = VehicleSimulator.new(config)
	race = RaceSession.new()
	_setup_environment()
	tree = TrackBuilder.build(self)
	car = VehicleBuilder.build(self)
	chase_camera = Camera3D.new()
	chase_camera.name = "Chase camera"
	chase_camera.current = true
	chase_camera.fov = 68.0
	add_child(chase_camera)
	_build_hud()
	_snap_visuals()
	_update_hud()

func _setup_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "Dusk environment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("101a2d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c3d5eb")
	env.ambient_light_energy = 0.65
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -26.0, 0.0)
	sun.light_color = Color("dce7f6")
	sun.light_energy = 1.4
	add_child(sun)

func _physics_process(dt: float) -> void:
	if race.phase == NoPrepRaceSession.Phase.FINISHED or race.phase == NoPrepRaceSession.Phase.RED_LIGHT:
		return
	var wants_throttle: bool = Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var wants_brake: bool = Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	var right: float = 1.0 if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) else 0.0
	var left: float = 1.0 if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) else 0.0
	input_throttle = move_toward(input_throttle, 1.0 if wants_throttle else 0.0, dt * 1.7)
	input_steer = move_toward(input_steer, right - left, dt * 4.0)
	if race.phase == NoPrepRaceSession.Phase.COUNTDOWN:
		race.step(dt, input_throttle, car_sim.distance_m, car_sim.speed_mps, car_sim.trajectory_foul)
		return
	if race.phase != NoPrepRaceSession.Phase.RUNNING:
		return
	car_sim.step(dt, input_throttle, input_steer, 1.0 if wants_brake else 0.0)
	race.step(dt, input_throttle, car_sim.distance_m, car_sim.speed_mps, car_sim.trajectory_foul)

func _process(delta: float) -> void:
	elapsed_visual_s += delta
	_update_visuals(delta)
	_update_hud()
	_update_tree_lamps()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_SPACE:
			race.stage()
		KEY_R:
			_restart()
		KEY_E:
			if race.phase == NoPrepRaceSession.Phase.RUNNING:
				car_sim.shift_up()
		KEY_Q:
			if race.phase == NoPrepRaceSession.Phase.RUNNING:
				car_sim.shift_down()
		KEY_X:
			config.boost_psi = minf(40.0, config.boost_psi + 2.0)
		KEY_Z:
			config.boost_psi = maxf(0.0, config.boost_psi - 2.0)
		KEY_V:
			config.tire_mu = minf(2.1, config.tire_mu + 0.05)
		KEY_C:
			config.tire_mu = maxf(0.5, config.tire_mu - 0.05)

func _restart() -> void:
	car_sim.reset()
	race.reset()
	input_throttle = 0.0
	input_steer = 0.0
	_snap_visuals()

func _snap_visuals() -> void:
	car.position = Vector3(car_sim.lane_x_m, 0.0, -car_sim.distance_m)
	car.rotation.y = -car_sim.heading_rad
	chase_camera.position = car.position + Vector3(2.2, 4.8, 10.0)
	chase_camera.look_at(car.position + Vector3(0.0, 1.25, -11.0))

func _update_visuals(dt: float) -> void:
	car.position = Vector3(car_sim.lane_x_m, 0.0, -car_sim.distance_m)
	car.rotation.y = -car_sim.heading_rad
	# Shaking is purely visual; physical state is not changed by it.
	var shake := minf(0.018, car_sim.slip_ratio * 0.012)
	car.position.y = sin(elapsed_visual_s * 40.0) * shake
	var target: Vector3 = car.position + Vector3(2.2, 4.8, 10.0)
	chase_camera.position = chase_camera.position.lerp(target, minf(1.0, 6.0 * dt))
	chase_camera.look_at(car.position + Vector3(0.0, 1.25, -11.0))

func _panel_style() -> StyleBoxFlat:
	var p := StyleBoxFlat.new()
	p.bg_color = Color(0.034, 0.058, 0.100, 0.91)
	p.border_color = Color(0.16, 0.39, 0.61, 0.85)
	p.set_border_width_all(1)
	p.set_corner_radius_all(12)
	p.content_margin_left = 16.0
	p.content_margin_right = 16.0
	p.content_margin_top = 12.0
	p.content_margin_bottom = 12.0
	return p

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "Race HUD"
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(337, 0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 7)
	panel.add_child(left)
	left.add_child(_label("NO-PREP  /  201 METROS", 15, Color("5be8f5")))
	status_label = _label("PRONTO PARA LARGAR", 23, Color.WHITE)
	left.add_child(status_label)
	stats_label = _label("", 16, Color("c5d2dc"))
	left.add_child(stats_label)
	tune_label = _label("", 14, Color("f7c67e"))
	left.add_child(tune_label)

	var speed_panel := PanelContainer.new()
	speed_panel.anchor_left = 1.0
	speed_panel.anchor_right = 1.0
	speed_panel.offset_left = -322
	speed_panel.offset_right = -18
	speed_panel.offset_top = 18
	speed_panel.offset_bottom = 155
	speed_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(speed_panel)
	var speed_box := VBoxContainer.new()
	speed_panel.add_child(speed_box)
	speed_box.add_child(_label("VELOCIDADE", 14, Color("5be8f5")))
	speed_label = _label("000 km/h", 42, Color.WHITE)
	speed_box.add_child(speed_label)
	speed_sub_label = _label("MARCHA 1  |  1100 RPM", 15, Color("c5d2dc"))
	speed_box.add_child(speed_sub_label)

	countdown_label = _label("", 74, Color("faca61"))
	countdown_label.anchor_left = 0.5
	countdown_label.anchor_right = 0.5
	countdown_label.offset_left = -220
	countdown_label.offset_right = 220
	countdown_label.offset_top = 145
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(countdown_label)

	var footer := PanelContainer.new()
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0
	footer.anchor_left = 0.5
	footer.anchor_right = 0.5
	footer.offset_left = -440
	footer.offset_right = 440
	footer.offset_top = -95
	footer.offset_bottom = -15
	footer.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(footer)
	footer_label = _label("ESPAÇO  LARGAR   |   W/S  ACELERAR/FREAR   |   A/D  DIRIGIR\nQ/E  MARCHAS   |   Z/X  TURBO   |   C/V  PNEUS   |   R  REINICIAR", 15, Color("e6e8ee"))
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(footer_label)

func _update_hud() -> void:
	if status_label == null:
		return
	match race.phase:
		NoPrepRaceSession.Phase.READY:
			status_label.text = "ESPAÇO PARA INICIAR"
		NoPrepRaceSession.Phase.COUNTDOWN:
			status_label.text = "PREPARE A LARGADA"
		NoPrepRaceSession.Phase.RUNNING:
			status_label.text = "NA PISTA"
		NoPrepRaceSession.Phase.FINISHED:
			status_label.text = "201 METROS CONCLUÍDOS"
		NoPrepRaceSession.Phase.RED_LIGHT:
			status_label.text = "QUEIMOU A LARGADA"
	var reaction_str := "--.---" if race.reaction_s < 0.0 else "%.3f" % race.reaction_s
	var et_str := "--.---" if not race.launched else "%.3f" % race.elapsed_s
	stats_label.text = "DISTÂNCIA: %6.1f / 201 m\nET: %s s  |  RT: %s s\nPATINAGEM: %5.1f%%  |  TROCAS: %d" % [minf(201.0, car_sim.distance_m), et_str, reaction_str, car_sim.slip_ratio * 100.0, car_sim.shift_count]
	if race.foul_centerline or car_sim.trajectory_foul:
		stats_label.text += "\nPENALIDADE: INVASÃO DA FAIXA"
	if race.phase == NoPrepRaceSession.Phase.FINISHED:
		stats_label.text += "\nVELOCIDADE FINAL: %.1f km/h" % race.trap_kmh
	tune_label.text = "TURBO: %.0f psi    PNEUS μ: %.2f" % [config.boost_psi, config.tire_mu]
	speed_label.text = "%03d km/h" % roundi(car_sim.speed_kmh())
	speed_sub_label.text = "MARCHA %d  |  %04d RPM" % [car_sim.gear, roundi(car_sim.rpm)]
	countdown_label.text = "" if race.phase == NoPrepRaceSession.Phase.READY else race.light_label()
	if race.phase == NoPrepRaceSession.Phase.RUNNING:
		countdown_label.modulate.a = maxf(0.0, 1.0 - race.green_wait_s * 0.9)
	else:
		countdown_label.modulate.a = 1.0
	if race.phase == NoPrepRaceSession.Phase.RED_LIGHT:
		countdown_label.add_theme_color_override("font_color", Color("ff5267"))
	elif race.phase == NoPrepRaceSession.Phase.RUNNING or race.phase == NoPrepRaceSession.Phase.FINISHED:
		countdown_label.add_theme_color_override("font_color", Color("6fffa1"))
	else:
		countdown_label.add_theme_color_override("font_color", Color("ffce71"))

func _update_tree_lamps() -> void:
	if tree.is_empty():
		return
	var bulbs: Array = tree["bulbs"]
	for i in range(bulbs.size()):
		(bulbs[i] as MeshInstance3D).material_override = tree["off"]
	if race.phase == NoPrepRaceSession.Phase.COUNTDOWN:
		var index: int = mini(2, int(floor(race.countdown_s / 0.9)))
		for i in range(index + 1):
			(bulbs[i] as MeshInstance3D).material_override = tree["amber"]
	elif race.phase == NoPrepRaceSession.Phase.RUNNING or race.phase == NoPrepRaceSession.Phase.FINISHED:
		(bulbs[3] as MeshInstance3D).material_override = tree["green"]
	elif race.phase == NoPrepRaceSession.Phase.RED_LIGHT:
		(bulbs[4] as MeshInstance3D).material_override = tree["red"]
