instrument = initInstrument()


_.defer ->
	d 'Starting'

	exercise = _.flatten([
		major(60)
		major(72)
		72 + 12 # Top C
		major(72).reverse()
		major(60).reverse()
	]).map (key, index) -> {
		key
		time: index # Time starts at zero and is incremented every beat.
		hand: 'left'
	}

	bpm = 120
	noteSize = 1 # Whole notes

	vis = d3.select('#exercise')

	# NOTE: This does not work. The height turns out to be the entire window height. Thought it worked yesterday?
	{ width, height } = vis.node().getBoundingClientRect()
	height = 300
	vis.attr({ width, height })

	pad = 40
	metronomeVis = M.metronome()
		.width(width)
		.pad(pad)
		.beats(exercise.length)
		.bpm(bpm)
		.vis(vis)

	metronomeVis()

	exerciseVis = M.exercise()
		.width(width)
		.height(height)
		.pad(pad)
		.bpm(bpm)
		.noteSize(noteSize)
		.vis(vis)

	start(exercise, bpm, noteSize)
		.on('start', (notes) ->
			exerciseVis.startTimeline(notes[notes.length - 1].expectedAt)
			Metronome.start(120)
		).on('update', (notes) -> exerciseVis.notes(notes))
		.on('complete', (notes) ->
			d 'Complete.'
		)

	# # NOTE: We'll want to record incomplete sessions and aborts, too.
	# And visits to the site.

start = (notes, bpm, noteSize) ->
	dispatch = d3.dispatch 'start', 'update', 'complete'

	# Session data for this instantiation of the notes
	data = notes.map (note) -> {
		key: note.key
		expectedAt: note.time * Theory.timeBetweenNotes(bpm, noteSize)
		playedAt: null
	}

	d data...

	startTime = null # Determined from the first keydown event
	instrument.on 'keydown.notes', (e) ->
		unless startTime?
			startTime = e.time
			dispatch.start(data)

		time = e.time - startTime
		index = findCorrespondingIndex e.key, time
		if index?
			note = data[index]
			note.playedAt = time
			note.error = note.playedAt - note.expectedAt
		else
			data.push {
				key: e.key
				expectedAt: null
				playedAt: time
			}


		d note

		dispatch.update(data)

	findCorrespondingIndex = (key, time) ->
		# Return the corresponding note from the exercise, or null if we didn't find one.
		# For now, scan linearly through the list, taking the closest unplayed matching note
		# within a temporal window. If there are several close-by notes, prefer the earliest
		# one inside the window.
		# NOTE: Extra notes end up at the back, unsorted. We'll want to revise this when we 
		# implement binary search.
		timeWindow = 2000
		for note, index in data
			# break unless note.playedAt? # Never skip past an unplayed note
			# If the note matches, was expected, hasn't been played, and is in our window, return it.
			if note.key == key and note.expectedAt? and not note.playedAt? and Math.abs(note.expectedAt - time) < timeWindow
				return index
		return null

	instrument.emulateKeysWithKeyboard notes.map ({key}) -> key

	# End the exercise once the amount of time that it takes has elapsed
	duration = (notes[notes.length - 1].time) * Theory.timeBetweenNotes(bpm, noteSize)
	endTimeout = setTimeout ->
		dispatch.complete(data)
	, duration

	# Expose an abort method, which ends the exercise early.
	dispatch.abort = ->
		instrument.stopEmulatingKeys()
		instrument.on('keydown.notes', null)
		clearTimeout endTimeout

	_.defer -> dispatch.update(data)
	dispatch

M = {
	metronome: ->
		opts = {
			beats: 50
			width: 300
			pad: 0
			bpm: 120
			vis: null
		}

		createElements = ->
			nome = opts.vis.select('.metronome')
			if nome.empty()
				nome = opts.vis.append('g').attr(class: 'metronome')

		render = ->
			beats = for num in [0...opts.beats]
				# NOTE: Notes and beats are not one-to-one.
				{ num, text: Theory.notes[num % 12] } 

			beatRadius = (d, i) -> 3 # if i % 4 then 2 else 6

			x = d3.scale.linear()
				.domain([0, opts.beats - 1])
				.range([opts.pad, opts.width - opts.pad])

			update = opts.vis.select('.metronome').selectAll('.beat').data(beats)
			enter = update.enter().append('g').attr(
				class: 'beat'
				transform: (d) -> "translate(#{x(d.num)}, 25)" # TODO: - beatRadius(d, i)
				opacity: 1e-6
			)
			enter.append('circle').attr(
				r: beatRadius
				fill: '#999'
			)
			# enter.append('text').attr(
			# 	y: 30
			# 	fill: '#999'
			# ).text((d) -> d.text)

			update.transition()
				.delay((d, i) -> i * 10)
				.duration(500)
				.ease('ease-out-expo')
				.attr({
					opacity: 1

				})
			update.exit().remove()

		_.accessors(render, opts)
			.addAll()
			.add('vis', createElements)
			.done()

	exercise: ->
		opts = {
			width: 500
			height: 300
			pad: 0
			bpm: 120
			noteSize: 1
			noteRadius: 3
			notes: [ ]
			vis: null
		}

		{ max, min, abs } = Math

		createElements = ->
			vis = opts.vis
			notes = vis.select('.notes')
			if notes.empty()
				notes = vis.append('g').attr(class: 'notes')
				timeline = vis.append('line').attr(
					class: 'timeline'
					x1: 0, y1: -9999
					x2: 0, y2: 9999,
					stroke: 'transparent'
				)

		render = ->
			data = opts.notes
			# TODO: Do we want to visualize real time, or with bpm normalized out?

			x = d3.scale.linear()
				.domain(d3.extent(data, (d) -> d.expectedAt))
				.range([opts.pad, opts.width - opts.pad])

			y = d3.scale.linear()
				.domain(d3.extent(data, (d) -> d.key))
				.range([opts.height, 0]) # Position higher notes higher up

			update = opts.vis.select('.notes').selectAll('.note').data(data)
			enter = update.enter().append('g').attr(
				class: 'note'
				transform: (d) -> "translate(#{x(d.expectedAt ? d.playedAt)}, #{y(d.key)})"
			)

			enter.append('circle').attr(
				class: 'indicator'
				r: opts.noteRadius
				fill: '#fff'
			)

			colorScale = d3.scale.linear()
				.domain([-1000, 0, 1000])
				.range(['#ff0000', '#fff', '#009eff'])
				.interpolate(d3.interpolateLab)
				.clamp(true)

			errorScale = (error) -> max(abs(x(error) - x(0)), 3)

			update.select('circle').transition().ease('cubic-out').duration(200).attr(
				r: (d) -> if d.error? then errorScale(d.error) else opts.noteRadius
				fill: (d) -> if d.error? then colorScale(d.error) else '#fff'
			)

		render.startTimeline = (duration) ->
			timeline = opts.vis.select('.timeline')
			# How accurate is this, given what we know about Javascript time? [It seems to be doing well enough, empirically.]
			# If we can't have precision, is it better to *not* have a visual cue?
			timeline
				.attr(transform: "translate(#{opts.pad}, 0)", stroke: '#fff')
				.transition()
				.duration(duration)
				.ease('linear')
				.attr(transform: "translate(#{opts.width - opts.pad}, 0)")

		render.stopTimeline = ->
			timeline = opts.vis.select('.timeline')
			timeline.interrupt().attr(stroke: 'transparent')

		_.accessors(render, opts).addAll()
			.add('notes', render)
			.add('vis', createElements)
			.done()


}
