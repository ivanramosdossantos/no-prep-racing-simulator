extends Resource
class_name NoPrepVehicleConfig
## The values in this resource are a generic fictional RWD drag car, not OEM data.

@export_group("Powertrain")
@export_range(150.0, 1400.0, 10.0) var base_torque_nm: float = 680.0
@export_range(0.0, 40.0, 1.0) var boost_psi: float = 12.0
@export_range(5000.0, 10000.0, 100.0) var rev_limit_rpm: float = 7600.0
@export_range(1800.0, 6000.0, 100.0) var launch_rpm: float = 3800.0
@export var idle_rpm: float = 1100.0
@export var gear_ratios: PackedFloat32Array = PackedFloat32Array([2.80, 1.90, 1.38, 1.08])
@export_range(2.0, 5.0, 0.05) var final_drive: float = 3.55
@export_range(0.65, 1.0, 0.01) var drivetrain_efficiency: float = 0.87

@export_group("Chassis")
@export_range(700.0, 2600.0, 25.0) var mass_kg: float = 1350.0
@export_range(0.2, 0.6, 0.01) var tire_radius_m: float = 0.345
@export_range(0.5, 2.1, 0.05) var tire_mu: float = 1.35
@export_range(0.4, 1.3, 0.05) var track_grip: float = 0.86
@export_range(0.45, 0.65, 0.01) var rear_weight_fraction: float = 0.54
@export_range(2.0, 3.4, 0.05) var wheelbase_m: float = 2.75
@export_range(0.3, 0.85, 0.05) var center_of_gravity_height_m: float = 0.55
@export_range(0.3, 1.7, 0.05) var drag_area_m2: float = 0.84
@export var rolling_resistance_coefficient: float = 0.014

func validated() -> bool:
	return mass_kg > 0.0 and tire_radius_m > 0.0 and wheelbase_m > 0.0 and gear_ratios.size() > 0 and rev_limit_rpm > idle_rpm
