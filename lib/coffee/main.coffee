log = (texts...) -> d3.select('#log').append('p', ':first-child').text(text) for text in texts

makePromise = (fn) ->
	defer = Q.defer()
	fn(defer)
	return defer.promise

expectKey = (k) ->
	makePromise (defer) ->
		key k, ->
			d 'Key pressed!'
			key.unbind k
			defer.resolve()

expectChord = (ks) ->
	makePromise (defer) ->
		n = ks.length
		for k in ks
			expectKey(k).then(-> d(1);defer.resolve() if --n == 0)
		return

expect = (ks) -> d('expecting', ks); -> expectChord(ks.split(''))

# ex = 'dh fj gk fj dh'.split(' ')
# ex.reduce(
# 	(p, ks, i) -> if i then p.then(expect ks) else p.fcall(expect ks)
# 	Q
# ).then(->
# 	d 'finished!'
# )

key 'a', -> d 'a'

initInstrument = ->
	dispatch = d3.dispatch 'ready', 'keydown', 'keyup', 'error'
	navigator.requestMIDIAccess().then(
		(midi) ->
			inputs = midi.inputs()
			if inputs.length
				inputs[0].onmidimessage = (e) ->
					[cmd, key, velocity] = e.data
					if cmd == 144 && velocity > 0
						# MIDI: Note on
						dispatch.keydown { key, velocity, time: e.timeStamp, event: e }
					else if cmd == 128 || (cmd == 144 && velocity == 0)
						# MIDI: Note off || Note on with velocity 0 (some instruments are known to do this.)
						dispatch.keyup { key, time: e.timeStamp, event: e }
				dispatch.ready(dispatch, inputs[0])
			else
				dispatch.error(true, null)

		(err) ->
			dispatch.error(false, err)
	)

	nextId = do ->
		next = 0
		(type) -> type + '.internal_' + next++

	untilTrue = (type, fn) ->
		id = nextId(type)
		dispatch.on(id, (args...) ->
			if fn(args...)
				dispatch.on(id, null)
		)

	dispatch.waitForPress = (key) ->
		d 'waiting for', key
		# TODO: We'll need a way to cancel these, too...
		makePromise (defer) ->
			untilTrue('keydown', (e) ->
				d 'checking for', key
				if e.key == key
					defer.resolve() 
					true
			)

	dispatch

# 72 = middle C

initInstrument()
	.on('keydown', (e) ->
		d 'Key down:', e.key, 'at speed', e.velocity
	).on('keyup', (e) ->
		d 'Key up:', e.key
	).on('error', (instrumentMissing, err) ->
		if instrumentMissing
			d 'You have no MIDI keyboard.'
		else
			d 'Error initializing MIDI connection:', err
	).on('ready', (instr, input) ->
		ex = [72, 74, 76, 77, 79, 77, 76, 74, 72]
		ex.reduce(
			(p, ks, i) -> if i then p.then(-> instr.waitForPress ks) else p.fcall(instr.waitForPress, ks)
			Q
		).then(->
			d 'finished!'
		)

	)



