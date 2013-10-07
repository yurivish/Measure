exercise = {
	notes: _.flatten [
		major(60)
		major(72)
		72 + 12 # Top C
		major(72).reverse()
	]
}

d 'Exercise:', exercise

instrument = initInstrument()

bpm = 120
bps = bpm / 60
interval = 1000 / bps

notes = exercise.notes.map (key, index) -> { key, index, offset: index * interval }

w = 900
xpos = d3.scale.linear().domain([0, notes.length - 1]).range([0, w])

parent = d3.select('#notes').append('g').attr('transform', 'translate(25, 225)')
update = parent.selectAll('.note').data(notes)
enter = update.enter().append('g').attr(
	class: 'note'
	transform: (d, i) ->
		"translate(#{xpos(i)}, 0)"
)

enter.append('circle').attr(
	class: 'indicator'
	r: 3
	fill: '#fff'
	cy: (d) -> -5 * (d.key - notes[0].key)
)
enter.append('circle').attr(
	class: 'anim'
	r: 3
	fill: '#fff'
	'fill-opacity': 1
	cy: (d) -> -5 * (d.key - notes[0].key)
)
update.each (d) -> d.sel = d3.select(this)

colorScale = d3.scale.linear()
	.domain([-10, 0, 10])
	.range(['#ff0000', '#fff', '#009eff'])
	.interpolate(d3.interpolateLab)
	.clamp(true)

timeline = parent.append('line').attr(class: 'timeline', x1: 0, y1: -25, x2: 0, y2: 25, stroke: '#fff')
start = (startTime) ->
	duration = interval * (notes.length - 1)
	endTime = startTime + duration

	# How accurate is this, really, given what we know about Javascript time?
	# Is it better to *not* have a visual cue, if we can't have precision?
	timeline
		.transition()
		.duration(duration)
		.ease('linear')
		.attr(transform: "translate(#{w}, 0)", fill: '#fff')

	# Locate a time on the x axis, or get the pixel size of a time slice
	timeToXAxis = d3.scale.linear().domain([0, duration]).range([0, w])
	error = (target, val) -> timeToXAxis(target - val)

	notePlayed = (note, time) ->
		note.sel.select('.anim')
			.transition()
			.ease('cubic-out')
			.duration(600)
			.attr('r', 20)
			.attr('fill-opacity', 1e-6)

		err = error(time, startTime + note.offset)

		note.sel.moveToBack()
		note.sel.select('.indicator')
			.transition().ease('cubic-out').duration(200)
			.attr('fill', colorScale(err))
			.attr('r', 3 + Math.abs(err))
		note.pressedAt = time

	instrument.on('keydown', (e) ->
		index = Math.floor (e.time - startTime) / interval
		prevNote = notes[index]
		nextNote = notes[index + 1]

		if prevNote? and not prevNote.pressedAt? and prevNote.key == e.key
			selectedNote = prevNote

		if nextNote? and not nextNote.pressedAt? and nextNote.key == e.key
			selectedNote = nextNote

		if selectedNote
			notePlayed selectedNote, e.time
	)

	notePlayed(notes[0], startTime)

	Metronome.start(bpm)
	setTimeout Metronome.stop, duration


instrument.fakeKeys exercise.notes # Listen for computer keyboard events

startId = instrument.watch('keydown', (e) ->
	start(e.time)
	instrument.unwatch(startId)
)
