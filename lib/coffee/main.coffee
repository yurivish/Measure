ascending = _.flatten [
	major(60)
	major(72)
	72 + 12
]

descending = _.flatten [
	major(72).reverse()
	major(60).reverse()
]

exercise = [
	{
		direction: 'ascending'
		notes: ascending.map (key, index) -> { key, index }
	}
	{
		direction: 'descending'
		notes: descending.map (key, index) -> { key, index }
	}
]

d exercise

sel = d3.select('#notes').append('g').attr('transform', 'translate(25, 25)')

noteIndicator = sel.append('g').attr('transform', 'translate(950, 100)')
noteIndicator.append('circle').attr(
	fill: '#333'
	stroke: '#333'
	r: 50
)
noteIndicator.append('text').attr(
	'text-anchor': 'middle'
	dy: '.35em'
	fill: '#fff'
)

# Idea: Animate notes horizontally, timed so that the ideal playthrough has no animation pauses.

indicate = (note) ->
	noteIndicator.select('text').text(note)
		.attr('transform', 'scale(1.1)')
		.interrupt().transition().duration(600).ease('cubic-out')
		.attr('transform', 'scale(1)')

	noteIndicator.select('circle').attr(
		stroke: '#888'
		# transform: 'scale(1.1)'
	)
	.interrupt().transition().duration(600).ease('cubic-out')
	.attr(
		stroke: '#333'
		# transform: 'scale(1)'
	)


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
				d 'Ready:', inputs[0]
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

visExercise = (exercise) ->
	update = sel.selectAll('.section').data(exercise)
	enter = update.enter().append('g').attr(class: 'section')

	heightSoFar = 0

	update
		.each(visSection)
		.attr(
			transform: (d, i) ->
				padding = 25
				offset = heightSoFar
				rect = this.getBoundingClientRect()
				heightSoFar += rect.height + padding
				"translate(0, #{ offset })"
		)

	sel.selectAll('.note')
		.attr(opacity: 1e-6)
		.transition().duration(600)
		.delay((d, i) -> i * 20)
		.attr(opacity: 1)

	rect = sel.node().getBoundingClientRect()
	d3.select('#notes').attr(height: rect.top + rect.height)

	i = 1
	pressed =  ->

		w = 800
		p = 1
		s = w / 8 - p
		note = d3.select('.note:nth-child(' + i++ + ')')
		indicate(note.select('text').text())

		note.select('.after')
			.transition().duration(400).ease('cubic-out')
			.attr(width: s)

		note.select('text')
			.transition().duration(400).ease('cubic-out')
			.attr('fill', '#000')
	initInstrument()
		.on('keydown', pressed)
		.on('error', (instrumentMissing, err) ->
			if instrumentMissing
				d 'You have no MIDI keyboard.'
			else
				d 'Error initializing MIDI connection:', err
		)



visSection = (section, i) ->

	w = 800
	p = 1
	s = w / 8 - p

	update = d3.select(this).selectAll('.note').data(section.notes)
	enter = update.enter().append('g').attr(class: 'note')
	# enter.append('circle').attr(r: s / 2, cx: s/2, cy: s/2)
	enter.append('rect').attr(height: s, width: s, class: 'before', fill: '#343434')
	enter.append('rect').attr(height: s, width: 0, class: 'after', fill: '#ccc')
	enter.append('text').attr('text-anchor': 'middle', x: s/2, y: s/2, dy: '.35em', fill: '#ddd')
		.text(-> ['C', 'D', 'E', 'F#'][~~(Math.random() * 4)])

	update.attr(
		transform: (d, i) ->
			x = i * (s + p) % w
			y = (s + p) *(~~((i / w) * (s + p)))
			"translate(#{x}, #{y})"
	).on('mouseenter', ->

	)




visExercise exercise