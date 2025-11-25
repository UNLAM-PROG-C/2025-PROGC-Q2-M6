extends Node


class TileColors:
	const LIGHT := Color(0.9, 0.9, 0.9)
	const DARK := Color(0.4, 0.3, 0.2)
	const HIGHLIGHT := Color(1.0, 0.85, 0.2, 0.6)

class MovementIndicatorConfig:
	const DIAMETER_RATIO := 0.75
	const LINE_WIDTH := 6
	const COLOR := Color(0,0,0,0.6)
	const POINTS := 128

class PlayerColor:
	const WHITE := "WHITE"
	const BLACK := "BLACK"

const TILE_SIZE := 80