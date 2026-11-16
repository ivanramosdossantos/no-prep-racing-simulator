extends RefCounted
class_name NoPrepVehicleSimulator
## A deterministic, fixed-dt longitudinal model and simplified bicycle steering.
## IMPORTANT: Traction degradation and launch clutch are *empirical approximations*.
## The rendered model never drives the physics. Real-time rendering only reads state.

const G: float = 9.81
const AIR_DENSITY: float = 1.225
const RACE_DISTANCE_M: float = 201.0

var config: NoPrepVehicleConfig
var distance_m: float = 0.0
var lane_x_m: float = 1.85
var heading_rad: float = 0.0
var speed_mps: float = 0.0
var acceleration_mps2: float = 0.0
var rpm: float = 1100.0
var wheel_rpm: float = 0.0
var slip_ratio: float = 0.0
var tire_preparation_grip_multiplier: float = 1.0
var throttle: float = 0.0
var steer: float = 0.0
var gear: int = 1
var elapsed_s: float = 0.0
var trajectory_foul: bool = false
var shift_count: int = 0
var _steer_angle_rad: float = 0.0

func _init(configuration: NoPrepVehicleConfig = null) -> void:
	config = configuration if configuration != null else NoPrepVehicleConfig.new()
	reset()

func reset() -> void:
	distance_m = 0.0
	lane_x_m = 1.85
	heading_rad = 0.0
	speed_mps = 0.0
	acceleration_mps2 = 0.0
	rpm = config.idle_rpm
	wheel_rpm = 0.0
	slip_ratio = 0.0
	tire_preparation_grip_multiplier = 1.0
	throttle = 0.0
	steer = 0.0
	gear = 1
	elapsed_s = 0.0
	trajectory_foul = false
	shift_count = 0
	_steer_angle_rad = 0.0

func shift_up() -> bool:
	if gear >= config.gear_ratios.size():
		return false
	gear += 1
	shift_count += 1
	return true

func shift_down() -> bool:
	if gear <= 1:
		return false
	gear -= 1
	shift_count += 1
	return true

func torque_nm(engine_rpm: float) -> float:
	# Smooth torque curve with a broad mid-RPM plateau; turbo is an adjustable multiplier.
	var distance_from_peak: float = (engine_rpm - 4900.0) / 3600.0
	var band: float = 0.51 + 0.49 * exp(-distance_from_peak * distance_from_peak)
	return config.base_torque_nm * band * (1.0 + config.boost_psi * 0.034)

func step(dt: float, requested_throttle: float, requested_steer: float, braking: float = 0.0) -> void:
	assert(config.validated(), "The vehicle setup must be valid")
	if dt <= 0.0:
		return
	throttle = clampf(requested_throttle, 0.0, 1.0)
	steer = clampf(requested_steer, -1.0, 1.0)
	var brake_input: float = clampf(braking, 0.0, 1.0)
	var ratio: float = config.gear_ratios[gear - 1] * config.final_drive
	# Below clutch lockup speed, the driver can hold a chosen launch RPM.
	var coupled_rpm: float = (speed_mps * (1.0 + slip_ratio) / (TAU * config.tire_radius_m)) * ratio * 60.0
	var launch_floor: float = lerpf(config.idle_rpm, config.launch_rpm, throttle) if speed_mps < 12.0 else config.idle_rpm
	rpm = clampf(maxf(coupled_rpm, launch_floor), config.idle_rpm, config.rev_limit_rpm)
	var limiter_factor: float = 0.0 if coupled_rpm > config.rev_limit_rpm else 1.0
	var axle_torque_nm: float = torque_nm(rpm) * throttle * ratio * config.drivetrain_efficiency * limiter_factor
	var demanded_force_n: float = axle_torque_nm / config.tire_radius_m

	# Positive acceleration transfers vertical load to rear drive axle (quasi-static).
	var rear_normal_n: float = config.mass_kg * G * config.rear_weight_fraction
	rear_normal_n += config.mass_kg * maxf(acceleration_mps2, 0.0) * config.center_of_gravity_height_m / config.wheelbase_m
	rear_normal_n = clampf(rear_normal_n, 0.0, config.mass_kg * G * 0.87)
	var traction_limit_n: float = maxf(100.0, rear_normal_n * config.tire_mu * config.track_grip * tire_preparation_grip_multiplier)
	# Excess torque increases spin, and high spin reduces the available tire force.
	# This is NOT a full tire force-vs-slip or individual-wheel dynamics model.
	var oversupply: float = demanded_force_n / traction_limit_n
	var target_slip: float = clampf(0.025 + maxf(0.0, oversupply - 0.88) * 0.52, 0.0, 1.8)
	slip_ratio = move_toward(slip_ratio, target_slip, 7.0 * dt)
	var spin_penalty: float = 1.0 + maxf(0.0, slip_ratio - 0.16) * 1.25
	var available_force_n: float = traction_limit_n / spin_penalty
	var drive_force_n: float = minf(demanded_force_n, available_force_n)

	var drag_n: float = 0.5 * AIR_DENSITY * config.drag_area_m2 * speed_mps * speed_mps
	var rolling_n: float = config.mass_kg * G * config.rolling_resistance_coefficient if speed_mps > 0.03 or demanded_force_n > 0.0 else 0.0
	var brake_force_n: float = brake_input * config.mass_kg * 8.0
	acceleration_mps2 = (drive_force_n - drag_n - rolling_n - brake_force_n) / config.mass_kg
	var old_speed: float = speed_mps
	speed_mps = maxf(0.0, speed_mps + acceleration_mps2 * dt)

	# Bicycle steering proxy; lateral grip and tire relaxation are future work.
	var max_steer_angle: float = deg_to_rad(12.0) / (1.0 + speed_mps / 14.0)
	_steer_angle_rad = move_toward(_steer_angle_rad, steer * max_steer_angle, 0.9 * dt)
	heading_rad += (speed_mps / config.wheelbase_m) * tan(_steer_angle_rad) * 0.36 * dt
	heading_rad = clampf(heading_rad, -0.55, 0.55)
	var average_speed: float = 0.5 * (old_speed + speed_mps)
	distance_m += average_speed * cos(heading_rad) * dt
	lane_x_m += average_speed * sin(heading_rad) * dt
	wheel_rpm = speed_mps * (1.0 + slip_ratio) * 60.0 / (TAU * config.tire_radius_m)
	elapsed_s += dt
	# Car half-width ~0.95m; crossing into the opposite lane is a race foul.
	if lane_x_m - 0.95 < 0.0 or lane_x_m + 0.95 > 3.75:
		trajectory_foul = true

func speed_kmh() -> float:
	return speed_mps * 3.6
