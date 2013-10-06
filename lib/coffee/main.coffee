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

	dispatch.waitForPress = (key) ->
		d 'waiting for', key
		# TODO: We'll need a way to cancel these, too...
		makePromise (defer) ->
			fulfillWhen defer, 'keydown' , (e) -> e.key == key

	dispatch

# 72 = middle C

notes = [ ]
visualize = ->
	now = Date.now()
	time = d3.scale.linear().domain([d3.min(notes, (d) -> d.time), now]).range([0, 900])
	update = d3.select('#notes').selectAll('.note').data(notes)
	enter = update.enter().append('rect').attr(class: 'note')
	update.attr(
		x: (d) -> time(d.time)
		y: 100
		width: (d) -> time(d.endTime ? now) - time(d.time)
		height: 15
		fill: '#ccc'
		'fill-opacity': 0.75
	)

	false

d3.timer(visualize)

active = { }
initInstrument()
	.on('keydown', ({ key, velocity, time }) ->
		# d 'Key down:', e.key, 'at speed', e.velocity
		note = { key, velocity, time }
		active[key] = note
		notes.push note

	).on('keyup', (e) ->
		# d 'Key up:', e.key
		if e.key of active
			active[e.key].endTime = e.time
	).on('error', (instrumentMissing, err) ->
		if instrumentMissing
			d 'You have no MIDI keyboard.'
		else
			d 'Error initializing MIDI connection:', err
	).on('ready', (instr, input) ->
		d 'Ready', input
		ex = [72, 74, 76, 77, 79, 77, 76, 74, 72]
		ex.reduce(
			(q, ks, i) -> 
				if i == 0
					q.fcall(-> instr.waitForPress ks)
				else
					q.then(-> instr.waitForPress ks)
			Q
		).then(->
			d 'finished!'
		)
	)



