



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

	# Pitches for MIDI notes based on standard concert pitch.
	# http://en.wikipedia.org/wiki/Scientific_pitch_notation
	# http://en.wikipedia.org/wiki/A440_(pitch_standard)
	pitches = [
		16.352 # C0
		17.324
		18.354
		19.445
		20.602
		21.827
		23.125
		24.500
		25.957
		27.500
		29.135
		30.868
		
		32.703 # C1
		34.648 
		36.708 
		38.891 
		41.203 
		43.654 
		46.249 
		48.999 
		51.913 
		55.000 
		58.270 
		61.735 

		65.406 # C2
		69.296 
		73.416 
		77.782 
		82.407 
		87.307 
		92.499 
		97.999 
		103.83 
		110.00 
		116.54 
		123.47 

		130.81 # C3
		138.59
		146.83
		155.56
		164.81
		174.61
		185.00
		196.00
		207.65
		220.00
		233.08
		246.94

		261.63 # C4 (Middle C)
		277.18
		293.66
		311.13
		329.63
		349.23
		369.99
		392.00
		415.30
		440.00 # A
		466.16
		493.88

		523.25 # C5
		554.37
		587.33
		622.25
		659.26
		698.46
		739.99
		783.99
		830.61
		880.00
		932.33
		987.77

		1046.5 # C6
		1108.7
		1174.7
		1244.5
		1318.5
		1396.9
		1480.0
		1568.0
		1661.2
		1760.0
		1864.7
		1975.5

		2093.0 # C7
		2217.5
		2349.3
		2489.0
		2637.0
		2793.8
		2960.0
		3136.0
		3322.4
		3520.0
		3729.3
		3951.1

		4186.0 # C8
		4434.9
		4698.6
		4978.0
		5274.0
		5587.7
		5919.9
		6271.9
		6644.9
		7040.0
		7458.6
		7902.1
	]

	Theory.major = (start) ->
		incs = [0, 2, 2, 1, 2, 2, 2] #, 1]
		offsets = do (note = 0) -> (note += inc for inc in incs)
		offsets.map (offset) -> start + offset

	Theory.pitchForKey = (key) -> pitches[key - 12]
	# d 'ix', _.indexOf(pitches, 261.63)
	# d Theory.pitchForKey 60
	Theory.nameForKey = (key, withNumber) -> notes[key % 12] + if withNumber then '' + Math.floor(key/12) - 1 else ''

