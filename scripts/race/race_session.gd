extends RefCounted
class_name NoPrepRaceSession
## Simplified drag racing timing: RT begins at green and ends on first motion.
## ET starts at first motion (0.2 m/s threshold), NOT the formal timing-beam rollout.
## Rollout/beam staging is planned for a later increment.

const RACE_DISTANCE_M: float = 201.0
const GREEN_AFTER_S: float = 2.7

enum Phase { READY, COUNTDOWN, RUNNING, FINISHED, RED_LIGHT }
var phase: Phase = Phase.READY
var countdown_s: float = 0.0
var green_wait_s: float = 0.0
var elapsed_s: float = 0.0
var reaction_s: float = -1.0
var trap_kmh: float = 0.0
var foul_centerline: bool = false
var launched: bool = false

func reset() -> void:
	phase = Phase.READY
	countdown_s = 0.0
	green_wait_s = 0.0
	elapsed_s = 0.0
	reaction_s = -1.0
	trap_kmh = 0.0
	foul_centerline = false
	launched = false

func stage() -> void:
	if phase != Phase.READY:
		return
	phase = Phase.COUNTDOWN
	countdown_s = 0.0

func step(dt: float, input_throttle: float, distance_m: float, speed_mps: float, has_centerline_foul: bool) -> void:
	if dt <= 0.0:
		return
	if phase == Phase.COUNTDOWN:
		if input_throttle > 0.18:
			phase = Phase.RED_LIGHT
			return
		countdown_s += dt
		if countdown_s >= GREEN_AFTER_S:
			phase = Phase.RUNNING
		return
	if phase != Phase.RUNNING:
		return
	foul_centerline = foul_centerline or has_centerline_foul
	if not launched:
		green_wait_s += dt
		if speed_mps >= 0.2:
			launched = true
			reaction_s = green_wait_s
	else:
		elapsed_s += dt
	if distance_m >= RACE_DISTANCE_M:
		phase = Phase.FINISHED
		trap_kmh = speed_mps * 3.6

func light_label() -> String:
	match phase:
		Phase.READY:
			return "STAGE"
		Phase.COUNTDOWN:
			if countdown_s < 0.9:
				return "3"
			if countdown_s < 1.8:
				return "2"
			return "1"
		Phase.RUNNING:
			return "GO!"
		Phase.FINISHED:
			return "FINISH"
		Phase.RED_LIGHT:
			return "RED LIGHT"
	return ""
