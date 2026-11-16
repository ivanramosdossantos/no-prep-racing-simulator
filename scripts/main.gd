extends Node3D
## I01 playable prototype. Keyboard only in this increment.
## Physical state lives in VehicleSimulator; meshes/camera are presentation only.

const VehicleSimulator = preload("res://scripts/simulation/vehicle_simulator.gd")
const VehicleConfig = preload("res://scripts/simulation/vehicle_config.gd")
const TirePreparation = preload("res://scripts/simulation/tire_preparation.gd")
const RaceSession = preload("res://scripts/race/race_session.gd")
const TrackBuilder = preload("res://scripts/visuals/track_builder.gd")
const VehicleBuilder = preload("res://scripts/visuals/vehicle_builder.gd")

var config: NoPrepVehicleConfig
var car_sim: NoPrepVehicleSimulator
var race: NoPrepRaceSession
var tire_prep: NoPrepTirePreparation
var camera_mode: int = 0
var tire_label: Label
var smoke_puffs: Array[MeshInstance3D] = []
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
	tire_prep = TirePreparation.new()
	_setup_environment()
	tree = TrackBuilder.build(self)
	car = VehicleBuilder.build(self)
	_build_smoke()
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
	if race.phase == NoPrepRaceSession.Phase.READY:
		var burning: bool = Input.is_key_pressed(KEY_B)
		tire_prep.step(dt, burning, false)
		car_sim.rpm = lerpf(config.idle_rpm, config.launch_rpm * 1.55, 1.0 if burning else 0.0)
		car_sim.tire_preparation_grip_multiplier = tire_prep.grip_multiplier()
		return
	if race.phase == NoPrepRaceSession.Phase.COUNTDOWN:
		tire_prep.step(dt, false, false)
		car_sim.tire_preparation_grip_multiplier = tire_prep.grip_multiplier()
		race.step(dt, input_throttle, car_sim.distance_m, car_sim.speed_mps, car_sim.trajectory_foul)
		return
	if race.phase != NoPrepRaceSession.Phase.RUNNING:
		return
	tire_prep.step(dt, false, true)
	car_sim.tire_preparation_grip_multiplier = tire_prep.grip_multiplier()
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
		KEY_TAB:
			camera_mode = (camera_mode + 1) % 3
			_snap_visuals()
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
	tire_prep.reset()
	input_throttle = 0.0
	input_steer = 0.0
	_snap_visuals()

func _snap_visuals() -> void:
	car.position = Vector3(car_sim.lane_x_m, 0.0, -car_sim.distance_m)
	car.rotation.y = -car_sim.heading_rad
	chase_camera.position = _camera_position()
	chase_camera.look_at(_camera_focus())

func _update_visuals(dt: float) -> void:
	car.position = Vector3(car_sim.lane_x_m, 0.0, -car_sim.distance_m)
	car.rotation.y = -car_sim.heading_rad
	# Shaking is purely visual; physical state is not changed by it.
	var shake := minf(0.018, car_sim.slip_ratio * 0.012)
	car.position.y = sin(elapsed_visual_s * 40.0) * shake
	var target: Vector3 = _camera_position()
	chase_camera.position = chase_camera.position.lerp(target, minf(1.0, 11.0 * dt) if camera_mode == 2 else minf(1.0, 6.0 * dt))
	chase_camera.look_at(_camera_focus())
	chase_camera.fov = lerpf(chase_camera.fov, 67.0 + minf(21.0, car_sim.speed_kmh() * 0.10), minf(1.0, 5.0 * dt))
	_update_smoke()
	_spin_wheels(dt)

func _camera_position() -> Vector3:
	match camera_mode:
		1:
			return car.position + Vector3(-3.4, 2.1, 6.4)
		2:
			return car.global_transform * Vector3(0.0, 1.40, -2.14)
	return car.position + Vector3(2.2, 4.8, 10.0)

func _camera_focus() -> Vector3:
	if camera_mode == 2:
		return car.global_transform * Vector3(0.0, 1.15, -22.0)
	return car.position + Vector3(0.0, 1.25, -11.0)

func _build_smoke() -> void:
	# Lightweight smoke made from original procedural spheres. No imported assets.
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	var smoke_material := StandardMaterial3D.new()
	smoke_material.albedo_color = Color(0.72, 0.76, 0.78, 0.37)
	smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(12):
		var puff := MeshInstance3D.new()
		puff.name = "Burnout smoke %d" % i
		puff.mesh = sphere
		puff.material_override = smoke_material
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		puff.visible = false
		car.add_child(puff)
		smoke_puffs.append(puff)

func _update_smoke() -> void:
	var burning: bool = race.phase == NoPrepRaceSession.Phase.READY and Input.is_key_pressed(KEY_B)
	var spinning: bool = race.phase == NoPrepRaceSession.Phase.RUNNING and car_sim.slip_ratio > 0.35
	for i in range(smoke_puffs.size()):
		var puff := smoke_puffs[i]
		puff.visible = burning or spinning
		if not puff.visible:
			continue
		var t: float = fposmod(elapsed_visual_s * 1.7 + float(i) * 0.143, 1.0)
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var scatter: float = sin(float(i) * 3.14 + elapsed_visual_s * 3.0) * 0.23
		puff.position = Vector3(side * (1.04 + 0.23 * t) + scatter, 0.44 + t * 1.25, 1.45 + t * 1.50)
		puff.scale = Vector3.ONE * (0.45 + t * 2.1)

func _spin_wheels(dt: float) -> void:
	var turns_per_second: float = car_sim.wheel_rpm / 60.0
	if race.phase == NoPrepRaceSession.Phase.READY and Input.is_key_pressed(KEY_B):
		turns_per_second = 11.0
	for wheel in car.find_children("Wheel", "Node3D", true, false):
		(wheel as Node3D).rotate_object_local(Vector3.UP, TAU * turns_per_second * dt)

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
	tire_label = _label("", 14, Color("c3e0f5"))
	left.add_child(tire_label)

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
	footer_label = _label("B  BURNOUT   |   ESPAÇO  STAGING   |   W/S  ACELERAR/FREAR   |   A/D  DIRIGIR\nQ/E  MARCHAS   |   TAB  CÂMERA   |   Z/X  TURBO   |   C/V  PNEUS   |   R  RESET", 14, Color("e6e8ee"))
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(footer_label)

func _update_hud() -> void:
	if status_label == null:
		return
	match race.phase:
		NoPrepRaceSession.Phase.READY:
			status_label.text = "B: AQUECER PNEUS  |  ESPAÇO: STAGE"
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
	tire_label.text = "BORRACHA: %02d%%  •  %s  |  GRIP: %.2fx" % [roundi(tire_prep.heat * 100.0), tire_prep.status(), tire_prep.grip_multiplier()]
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
