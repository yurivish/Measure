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

	dispatch.waitForPress = (key) ->
		d 'waiting for', key
		# TODO: We'll need a way to cancel these, too...
		makePromise (defer) ->
			fulfillWhen defer, 'keydown' , (e) -> e.key == key

	dispatch



# 72 = middle C

notes = [ ]
# color scheme
visualizeAsRects = ->
	now = Date.now()
	time = d3.scale.linear().domain([now - 2 * 1000, now]).range([0, 900])
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

sel = d3.select('#notes').append('g').attr('transform', 'translate(25, 25)')
visualize = ->
	now = Date.now()

	w = 500
	p = 25
	s = w / 6 - p

	update = sel.selectAll('.note').data(notes)
	enter = update.enter().append('rect').attr(class: 'note')

	update.attr(
		x: (d, i) -> i * (s + p) % w
		y: (d, i) -> (s + p) * ~~(i * (s + p) / w)
		fill: '#ccc'
		'fill-opacity': 0.75
		width: s
		height: s
	).transition().attr(

	)
	false

# d3.timer(visualize)

flash = (color) ->
	d3.select('body')
		.style('background', color)
		.interrupt().transition().ease('expo-out').duration(500)
		.style('background', '#000')

active = { }
initInstrument()
	.on('keydown', ({ key, velocity, time }) ->
		# d 'Key down:', e.key, 'at speed', e.velocity
		note = { key, velocity, time }
		active[key] = note
		notes.push note
		_.defer visualize
		# flash '#274a01'
	).on('keyup', (e) ->
		# d 'Key up:', e.key
		if e.key of active
			active[e.key].endTime = e.time
		_.defer visualize
		# flash '#4a0101'
		
	).on('error', (instrumentMissing, err) ->
		if instrumentMissing
			d 'You have no MIDI keyboard.'
		else
			d 'Error initializing MIDI connection:', err
	).on('ready', (instr, input) ->
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



