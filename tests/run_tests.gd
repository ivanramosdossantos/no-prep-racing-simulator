extends SceneTree
## Run with: godot --headless --path . --script res://tests/run_tests.gd

const Config = preload("res://scripts/simulation/vehicle_config.gd")
const Vehicle = preload("res://scripts/simulation/vehicle_simulator.gd")
const TirePrep = preload("res://scripts/simulation/tire_preparation.gd")
const Race = preload("res://scripts/race/race_session.gd")

var checks: int = 0
var failures: int = 0

func _init() -> void:
	call_deferred("_run_all")

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)
	else:
		print("PASS: " + description)

func _drive(config: NoPrepVehicleConfig, throttle: float, ticks: int, auto_shift: bool = false) -> NoPrepVehicleSimulator:
	var car := Vehicle.new(config)
	for i in range(ticks):
		if auto_shift and car.rpm > 7000.0:
			car.shift_up()
		car.step(1.0 / 120.0, throttle, 0.0)
	return car

func _run_all() -> void:
	var prep := TirePrep.new()
	var cold_grip: float = prep.grip_multiplier()
	for i in range(400):
		prep.step(1.0 / 120.0, true, false)
	_check(prep.heat > 0.50, "Burnout warms tires at fixed physics steps")
	_check(prep.grip_multiplier() > cold_grip, "Moderate burnout improves grip over cold tires")
	for i in range(1000):
		prep.step(1.0 / 120.0, true, false)
	_check(prep.grip_multiplier() < 1.0, "Overheated tires lose launch traction")
	prep.reset()
	_check(is_equal_approx(prep.heat, 0.22), "Restart restores cold tire temperature")
	var prep_traction := Vehicle.new()
	var raw_traction := Vehicle.new()
	prep_traction.tire_preparation_grip_multiplier = 1.05
	raw_traction.tire_preparation_grip_multiplier = 0.78
	for i in range(120):
		prep_traction.step(1.0 / 120.0, 1.0, 0.0)
		raw_traction.step(1.0 / 120.0, 1.0, 0.0)
	_check(prep_traction.distance_m > raw_traction.distance_m, "Prepped tires transfer more launch force to the track")
	var config := Config.new()
	_check(config.validated(), "Stock setup is valid")
	var idling := _drive(Config.new(), 0.0, 480)
	_check(is_equal_approx(idling.speed_mps, 0.0), "Car remains stationary without throttle")

	var launching := _drive(Config.new(), 0.85, 240)
	_check(launching.speed_mps > 1.0, "Throttle produces real acceleration")
	_check(launching.distance_m > 1.0, "Physical state records distance")
	_check(launching.slip_ratio >= 0.0, "Slip stays nonnegative")

	var no_grip := Config.new()
	no_grip.track_grip = 0.48
	var with_grip := Config.new()
	with_grip.track_grip = 1.20
	var poor := _drive(no_grip, 1.0, 80)
	var better := _drive(with_grip, 1.0, 80)
	_check(poor.slip_ratio > better.slip_ratio, "Lower track grip increases wheelspin")

	var boost_lo := Config.new()
	boost_lo.boost_psi = 0.0
	var boost_hi := Config.new()
	boost_hi.boost_psi = 25.0
	_check(Vehicle.new(boost_hi).torque_nm(4900.0) > Vehicle.new(boost_lo).torque_nm(4900.0), "Boost affects engine torque")

	var shift_car := Vehicle.new()
	_check(not shift_car.shift_down(), "Cannot shift below first")
	_check(shift_car.shift_up() and shift_car.gear == 2, "Manual upshift selects next gear")
	shift_car.shift_up()
	shift_car.shift_up()
	_check(not shift_car.shift_up() and shift_car.gear == 4, "Cannot shift above final gear")

	var steering_car := Vehicle.new()
	for i in range(240):
		steering_car.step(1.0 / 120.0, 0.65, -0.25)
	_check(steering_car.lane_x_m < 1.85, "Manual steering changes vehicle lateral position")

	var a := _drive(Config.new(), 0.8, 600, true)
	var b := _drive(Config.new(), 0.8, 600, true)
	_check(absf(a.distance_m - b.distance_m) < 0.000001, "Same inputs generate same distance")
	_check(absf(a.speed_mps - b.speed_mps) < 0.000001, "Same inputs generate same speed")

	var finish_car := Vehicle.new()
	for i in range(120 * 30):
		if finish_car.rpm > 7000.0:
			finish_car.shift_up()
		finish_car.step(1.0 / 120.0, 0.80, 0.0)
		if finish_car.distance_m >= 201.0:
			break
	_check(finish_car.distance_m >= 201.0, "Vehicle completes the 201-meter distance")
	print("TRACE: ET-ish physical travel %.3f s, trap %.1f km/h, gear %d" % [finish_car.elapsed_s, finish_car.speed_kmh(), finish_car.gear])

	var race := Race.new()
	race.stage()
	race.step(0.05, 0.9, 0.0, 0.0, false)
	_check(race.phase == Race.Phase.RED_LIGHT, "Throttle before green causes red light")
	race.reset()
	race.stage()
	for i in range(330):
		race.step(1.0 / 120.0, 0.0, 0.0, 0.0, false)
	_check(race.phase == Race.Phase.RUNNING, "Countdown goes green after 2.7 seconds")
	race.step(0.2, 0.5, 0.7, 0.5, false)
	_check(race.launched and race.reaction_s > 0.0, "Reaction is measured after vehicle moves")
	race.step(5.0, 1.0, 201.0, 36.0, true)
	_check(race.phase == Race.Phase.FINISHED, "Crossing 201 meters ends the race")
	_check(race.foul_centerline, "Crossing centerline is recorded as a foul")
	_check(race.trap_kmh > 100.0, "Trap speed is recorded at finish")

	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
