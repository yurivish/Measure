
notes = [
	'C', 'C#'
	'D', 'D#'
	'E'
	'F', 'F#'
	'G', 'G#'
	'A', 'A#'
	'B'
]

major = (start) ->
	incs = [0, 2, 2, 1, 2, 2, 2] #, 1]
	offsets = do (note = 0) -> (note += inc for inc in incs)
	offsets.map (offset) -> start + offset
