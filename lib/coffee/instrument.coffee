makePromise = (fn) ->
	defer = Q.defer()
	fn(defer)
	return defer.promise

initInstrument = ->
	dispatch = d3.dispatch 'ready', 'keydown', 'keyup', 'error'
	navigator.requestMIDIAccess().then(
		(midi) ->
			inputs = midi.inputs()
			d inputs
			if inputs.length
				inputs[0].onmidimessage = (e) ->
					[cmd, key, velocity] = e.data
					if cmd == 144 && velocity > 0
						# MIDI: Note on
						# d 'Key down:', key
						dispatch.keydown { key, velocity, time: e.receivedTime, event: e }
					else if cmd == 128 || (cmd == 144 && velocity == 0)
						# MIDI: Note off || Note on with velocity 0 (some instruments are known to do this.)
						dispatch.keyup { key, time: e.receivedTime, event: e }
				d 'Ready:', inputs[0] # BUG: Without the statement, the instrument fails to initlalize.
				dispatch.ready(dispatch, inputs[0])
			else	
				dispatch.error(true, null)

		(err) ->
			dispatch.error(false, err)
	)


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

	dispatch.emulateKeysWithKeyboard = (keys) ->
		up = down = 0
		d3.select(document)
			.on('keydown.internal', ->
				if d3.event.keyCode == 32
					dispatch.keydown({ key: keys[down++] ? 72, velocity: 50, time: performance.now(), event: null }))
			.on('keyup.internal', -> 
				if d3.event.keyCode == 32
					dispatch.keyup({ key: keys[up++] ? 72, time: performance.now(), event: null }))

	dispatch.stopEmulatingKeys = ->
		d3.select(document).on('keydown.internal', null).on('keyup.internal', null)

	dispatch.watch = (name, listener) ->
		id = tag(name)
		dispatch.on(id, listener)
		id
		
	dispatch.unwatch = (id) ->
		dispatch.on(id, null)

	dispatch.watchOnce = (name, listener) ->
		id = instrument.watch(name, (e) ->
			listener(e)
			dispatch.unwatch(id)
		)
		id

	dispatch.waitForPress = (key) ->
		# TODO: We'll need a way to cancel these, too...
		makePromise (defer) ->
			fulfillWhen defer, 'keydown' , (e) -> e.key == key

	dispatch
