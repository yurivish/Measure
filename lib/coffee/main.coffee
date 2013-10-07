exercise = {
	notes: _.flatten [
		major(60)
		# major(72)
		# 72 + 12 # Top C
		# major(72).reverse()
		60 + 12
		major(60).reverse()
	]
}

d 'Exercise:', exercise

instrument = initInstrument()

interval = 500
notes = exercise.notes.map (key, index) -> { key, index, offset: index * interval }

w = 600

xpos = d3.scale.linear().domain([0, notes.length - 1]).range([0, w])

parent = d3.select('#notes').append('g').attr('transform', 'translate(25, 125)')
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
)
enter.append('circle').attr(
	class: 'anim'
	r: 3
	fill: '#fff'
	'fill-opacity': 1
)
update.each (d) -> d.sel = d3.select(this)

colorScale = d3.scale.linear()
	.domain([-25, 0, 25])
	.range(['#ff0000', '#fff', '#009eff'])
	.interpolate(d3.interpolateLab)
	.clamp(true)


timeline = parent.append('line').attr(class: 'timeline', x1: 0, y1: -25, x2: 0, y2: 25, stroke: '#fff')
start = ->
	startTime = Date.now()
	duration = interval * (notes.length - 1)
	endTime = startTime + duration

	timeline
		.transition()
		.duration(duration)
		.ease('linear')
		.attr(transform: "translate(#{w}, 0)")

	timelineScale = d3.scale.linear().domain([0, duration]).range([0, w])
	error = (target, val) ->
		timelineScale(target - val)

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
		now = Date.now()
		index = Math.floor (now - startTime) / interval
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

instrument.fakeKeys exercise.notes

startId = instrument.watch('keydown', ->
	start()
	instrument.unwatch(startId)
)
