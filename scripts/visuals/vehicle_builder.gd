extends RefCounted
class_name NoPrepVehicleBuilder
## Provisional, royalty-free vehicle built entirely from engine primitives.

const TrackBuilder = preload("res://scripts/visuals/track_builder.gd")

static func build(parent: Node3D) -> Node3D:
	var car := Node3D.new()
	car.name = "No-Prep prototype car"
	parent.add_child(car)
	var paint := TrackBuilder.mat(Color("1263bd"), 0.24, 0.36)
	var midnight := TrackBuilder.mat(Color("0a1525"), 0.24, 0.20)
	var black := TrackBuilder.mat(Color("0d1119"), 0.92)
	var window := TrackBuilder.mat(Color("16374b"), 0.12, 0.3)
	var metal := TrackBuilder.mat(Color("909baa"), 0.24, 0.85)
	var white := TrackBuilder.mat(Color("e7edf4"), 0.3, 0.0, true)
	var tail := TrackBuilder.mat(Color("ff304c"), 0.4, 0.0, true)
	var rubber := TrackBuilder.mat(Color("14161a"), 0.98)
	# Profile resembles a generic long-hood racing coupe, no maker trademarks.
	TrackBuilder.block(car, "Chassis", Vector3(1.93, 0.50, 4.8), Vector3(0, 0.77, 0.0), paint)
	TrackBuilder.block(car, "Hood", Vector3(1.76, 0.12, 1.78), Vector3(0, 1.07, -1.35), paint)
	TrackBuilder.block(car, "Roof", Vector3(1.50, 0.16, 1.46), Vector3(0, 1.58, 0.32), paint)
	TrackBuilder.block(car, "Cabin", Vector3(1.62, 0.56, 1.63), Vector3(0, 1.27, 0.32), window)
	TrackBuilder.block(car, "Trunk", Vector3(1.72, 0.13, 0.70), Vector3(0, 1.05, 1.90), paint)
	TrackBuilder.block(car, "Front grille", Vector3(1.55, 0.31, 0.08), Vector3(0, 0.77, -2.43), midnight)
	TrackBuilder.block(car, "Front bumper", Vector3(1.82, 0.16, 0.16), Vector3(0, 0.49, -2.43), midnight)
	TrackBuilder.block(car, "Rear bumper", Vector3(1.86, 0.17, 0.17), Vector3(0, 0.52, 2.43), midnight)
	for x in [-0.78, 0.78]:
		TrackBuilder.block(car, "Headlamp", Vector3(0.34, 0.11, 0.06), Vector3(x, 0.95, -2.45), white)
		TrackBuilder.block(car, "Tail lamp", Vector3(0.38, 0.12, 0.05), Vector3(x, 0.87, 2.45), tail)
		TrackBuilder.block(car, "Side skirt", Vector3(0.10, 0.13, 2.37), Vector3(x * 1.26, 0.47, 0.0), midnight)
	for z in [-1.46, 1.46]:
		for side in [-1.0, 1.0]:
			var wheel := Node3D.new()
			wheel.name = "Wheel"
			wheel.position = Vector3(side * 1.01, 0.42, z)
			wheel.rotation_degrees.z = 90
			car.add_child(wheel)
			TrackBuilder.cylinder(wheel, "Tire", 0.43, 0.28, Vector3.ZERO, rubber)
			TrackBuilder.cylinder(wheel, "Wheel center", 0.27, 0.29, Vector3.ZERO, metal)
			TrackBuilder.cylinder(wheel, "Hub", 0.10, 0.30, Vector3.ZERO, midnight)
	# Rear drag wing and stripe are deliberately generic.
	TrackBuilder.block(car, "Spoiler support L", Vector3(0.08, 0.34, 0.10), Vector3(-0.64, 1.29, 2.12), midnight)
	TrackBuilder.block(car, "Spoiler support R", Vector3(0.08, 0.34, 0.10), Vector3(0.64, 1.29, 2.12), midnight)
	TrackBuilder.block(car, "Spoiler wing", Vector3(1.78, 0.07, 0.44), Vector3(0, 1.48, 2.20), midnight)
	TrackBuilder.block(car, "Racing stripe", Vector3(0.16, 0.02, 1.62), Vector3(-0.24, 1.142, -1.36), metal)
	return car
