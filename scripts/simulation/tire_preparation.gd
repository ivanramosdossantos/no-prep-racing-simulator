extends RefCounted
class_name NoPrepTirePreparation
## Original empirical tire-prep mechanic for our own No-Prep game.
## Does not use code, datasets, coefficients or assets from any commercial game.

const TARGET_HEAT: float = 0.66
var heat: float = 0.22
var burnout_duration_s: float = 0.0

func reset() -> void:
	heat = 0.22
	burnout_duration_s = 0.0

func step(dt: float, holding_burnout: bool, on_track: bool) -> void:
	if dt <= 0.0:
		return
	if holding_burnout and not on_track:
		burnout_duration_s += dt
		heat = minf(1.0, heat + (0.11 + (1.0 - heat) * 0.055) * dt)
	elif on_track:
		heat = move_toward(heat, 0.30, dt * 0.025)
	else:
		heat = move_toward(heat, 0.22, dt * 0.013)

func grip_multiplier() -> float:
	# Bell-shaped approximation, not a calibrated real-world tire compound.
	# Both cold rubber and overheated rubber can lose launch traction.
	var offset: float = (heat - TARGET_HEAT) / 0.26
	return 0.78 + 0.27 * exp(-offset * offset)

func status() -> String:
	if heat < 0.46:
		return "FRIO"
	if heat > 0.85:
		return "SUPERAQUECIDO"
	if absf(heat - TARGET_HEAT) <= 0.12:
		return "NA JANELA"
	return "AQUECENDO"
