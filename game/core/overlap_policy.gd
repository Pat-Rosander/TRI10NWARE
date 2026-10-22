# The overlap policy (P-04) in one place: when a switch makes a platform family solid while the
# body overlaps some of its tiles, decides whether the family is simply solid, the player snaps
# up onto a top (a landing), or the overlapped tiles wait as pending. Never pushes the player
# sideways or down. Serves AC P-04.
class_name OverlapPolicy
extends RefCounted

## What happens to the newly solid family.
enum Result { SOLID, SNAP, PENDING }

var _snap_px: int


## [param overlap_snap_px] comes from tuning: the deepest the feet may be below a top and still
## snap onto it.
func _init(overlap_snap_px: int) -> void:
	_snap_px = overlap_snap_px


## [param overlapped] is how many tiles of the newly solid family the body overlaps.
## [param feet_depth] is how far the feet are below the highest top of the overlapped tiles under
## the feet, or 0 if none is under the feet. [param vy] is the vertical speed (positive is down).
## [param fits] is whether the body fits at the snapped position. SOLID if nothing is overlapped;
## SNAP if the feet are within overlap_snap_px of the top, moving down or not at all, and the
## body fits; PENDING otherwise.
func decide(overlapped: int, feet_depth: int, vy: float, fits: bool) -> Result:
	if overlapped == 0:
		return Result.SOLID
	if feet_depth >= 1 and feet_depth <= _snap_px and vy >= 0.0 and fits:
		return Result.SNAP
	return Result.PENDING
