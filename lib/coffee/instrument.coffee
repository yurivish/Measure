makePromise = (fn) ->
	defer = Q.defer()
	fn(defer)
	return defer.promise

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
						d 'Key down:', key
						dispatch.keydown { key, velocity, time: e.timeStamp, event: e }
					else if cmd == 128 || (cmd == 144 && velocity == 0)
						# MIDI: Note off || Note on with velocity 0 (some instruments are known to do this.)
						dispatch.keyup { key, time: e.timeStamp, event: e }
				d 'Ready:', inputs[0] # BUG: Without the statement, the instrument fails to initlalize.
				dispatch.ready(dispatch, inputs[0])
			else
				dispatch.error(true, null)

		(err) ->
			dispatch.error(false, err)
	)

	d3.select(document)
		.on('keydown', -> dispatch.keydown({ key: 72, velocity: 50, time: Date.now(), event: null }))
		.on('keyup', -> dispatch.keyup({ key: 72, time: Date.now(), event: null }))

	tag = do ->
		next = 0
		(type) -> type + '.internal_' + next++

	fulfillWhen = (defer, type, condition) ->
		type = tag(type)
		dispatch.on(type, (args...) ->
			if condition(args...)
				defer.resolve()
				dispatch.on(type, null)
		)

	dispatch.watch = (name, listener) ->
		id = tag(name)
		dispatch.on(id, listener)
		id
		
	dispatch.unwatch = (id) ->
		dispatch.on(id, null)

	dispatch.waitForPress = (key) ->
		d 'waiting for', key
		# TODO: We'll need a way to cancel these, too...
		makePromise (defer) ->
			fulfillWhen defer, 'keydown' , (e) -> e.key == key

	dispatch
