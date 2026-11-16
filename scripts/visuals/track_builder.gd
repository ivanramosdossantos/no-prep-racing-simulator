extends RefCounted
class_name NoPrepTrackBuilder
## Procedural placeholder track. No outside assets or third-party logos.

static func mat(color: Color, roughness: float = 0.75, metallic: float = 0.0, glow: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	if glow:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = 1.8
	return result

static func block(parent: Node3D, label: String, dimensions: Vector3, center: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var part := MeshInstance3D.new()
	part.name = label
	part.mesh = mesh
	part.material_override = material
	part.position = center
	parent.add_child(part)
	return part

static func cylinder(parent: Node3D, label: String, radius: float, height: float, center: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	var part := MeshInstance3D.new()
	part.name = label
	part.mesh = mesh
	part.material_override = material
	part.position = center
	parent.add_child(part)
	return part

static func build(root: Node3D) -> Dictionary:
	var tarmac := mat(Color("151a20"), 0.98)
	var stripe := mat(Color("b9b8a7"), 0.85)
	var border := mat(Color("e8e4d7"), 0.8)
	var grass := mat(Color("182c29"), 1.0)
	var barrier := mat(Color("4d6573"), 0.5, 0.45)
	var yellow := mat(Color("f4ba34"), 0.5, 0.0, true)
	var green := mat(Color("3cdd84"), 0.5, 0.0, true)
	var red := mat(Color("f24d55"), 0.5, 0.0, true)
	var off := mat(Color("30383f"), 0.6)
	var ground := block(root, "Terrain", Vector3(170.0, 0.1, 350.0), Vector3(0.0, -0.16, -99.0), grass)
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	block(root, "No-prep tarmac", Vector3(11.0, 0.12, 252.0), Vector3(0.0, -0.055, -100.0), tarmac)
	for x in [-3.75, 0.0, 3.75]:
		block(root, "Track lane line", Vector3(0.09, 0.012, 221.0), Vector3(x, 0.012, -99.0), border)
	for i in range(23):
		var at_z := -float(i) * 9.5
		block(root, "Left wall", Vector3(0.22, 0.80, 9.2), Vector3(-5.45, 0.40, at_z), barrier)
		block(root, "Right wall", Vector3(0.22, 0.80, 9.2), Vector3(5.45, 0.40, at_z), barrier)
	for i in range(43):
		var at_z := -float(i) * 5.0
		block(root, "Reflector left", Vector3(0.20, 0.08, 0.25), Vector3(-5.32, 0.70, at_z), stripe)
		block(root, "Reflector right", Vector3(0.20, 0.08, 0.25), Vector3(5.32, 0.70, at_z), stripe)
	block(root, "Start line", Vector3(7.5, 0.016, 0.30), Vector3(0.0, 0.017, 0.0), border)
	block(root, "201 m finish line", Vector3(7.5, 0.016, 0.42), Vector3(0.0, 0.017, -201.0), yellow)
	# Light-up tree deliberately small, located outside the racing lanes.
	block(root, "Tree pole", Vector3(0.16, 3.4, 0.16), Vector3(-4.50, 1.8, -4.0), barrier)
	var bulbs: Array[MeshInstance3D] = []
	for i in range(3):
		bulbs.append(cylinder(root, "Amber %d" % (i + 1), 0.19, 0.12, Vector3(-4.50, 2.8 - float(i) * 0.48, -3.9), off))
	bulbs.append(cylinder(root, "Green", 0.19, 0.12, Vector3(-4.5, 1.36, -3.9), off))
	bulbs.append(cylinder(root, "Red", 0.19, 0.12, Vector3(-4.5, 0.91, -3.9), off))
	for item in bulbs:
		item.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	# Light sources placed away from the racing line to avoid complicating control.
	for i in range(7):
		var z := -float(i) * 33.0
		for side in [-1.0, 1.0]:
			block(root, "Light pole", Vector3(0.17, 8.0, 0.17), Vector3(side * 8.0, 4.0, z), barrier)
			block(root, "Floodlight", Vector3(0.8, 0.3, 0.55), Vector3(side * 8.0, 8.08, z), stripe)
			var source := OmniLight3D.new()
			source.position = Vector3(side * 7.5, 7.9, z)
			source.light_energy = 1.25
			source.omni_range = 20.0
			root.add_child(source)
	return {"bulbs": bulbs, "amber": yellow, "green": green, "red": red, "off": off}
