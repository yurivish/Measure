
Theory = { }
do ->
	notes = [
		'C', 'C#'
		'D', 'D#'
		'E'
		'F', 'F#'
		'G', 'G#'
		'A', 'A#'
		'B'
	]

	Theory.major = (start) ->
		incs = [0, 2, 2, 1, 2, 2, 2] #, 1]
		offsets = do (note = 0) -> (note += inc for inc in incs)
		offsets.map (offset) -> start + offset

	Theory.noteNameForKey = (key) -> notes[key % 12]
	Theory.timeBetweenNotes = (bpm, noteSize) -> noteSize * 1000 / (bpm / 60)