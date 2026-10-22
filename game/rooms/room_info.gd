# One room's design record: how each entrance is meant to be entered, the volts one attempt
# spends, where the room recharges the player and the intended route. Saved inside the room
# scene; read by the debug overlay (M1.7) and copied into the ledger. Rules never read it.
# Serves AC G-03.
class_name RoomInfo
extends Resource

## The state the room assumes at each entrance, keyed by `entrance_id`.
@export var entry_states: Dictionary[StringName, FlowLedger.State] = {}
## The volts the room assumes at each entrance (0 to `max_volts`), keyed by `entrance_id`.
@export var entry_volts: Dictionary[StringName, int] = {}
## The volts one attempt spends, at most 3: dying refills volts, so the budget is per attempt.
@export_range(0, 3) var volt_budget: int = 0
## The room's power sources (from M5), as paths from the room's root node.
@export var recharge_points: Array[NodePath] = []
## The intended completion route, from an entrance to a goal or opening.
@export_multiline var route: String = ""
## Anything else a designer or tester should know.
@export_multiline var notes: String = ""
