instrument = initInstrument()

# d3.select('body').on 'click', ->
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

	opts = do (bpm = 120) -> {
		bpm: bpm
		noteInterval: 1000 / (bpm / 60)
	}

	visualizer = Visualizer(
		d3.select('#notes').append('g').attr('transform', 'translate(50, 50)')
		width: 900, height: 400
	)

	start(exercise, opts)
		.on('start', (data) ->
			visualizer.playTimeline(data[data.length - 1].expectedAt)

		).on('update', (data) -> visualizer data)
		.on('complete', (data) ->
			d 'Complete.'
		)

	# NOTE: We'll want to record incomplete sessions and aborts, too.
	# And visits to the site.

start = (exercise, opts) ->
	dispatch = d3.dispatch 'start', 'update', 'complete'
	# Session data for this instantiation of the exercise
	data = exercise.map (note) -> {
		key: note.key
		expectedAt: note.time * opts.noteInterval
		playedAt: null
	}

	startTime = null # Determined from the first keydown event
	instrument.on 'keydown.exercise', (e) ->
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

		d index

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

	instrument.emulateKeysWithKeyboard exercise.map ({key}) -> key

	# End the exercise once the amount of time that it takes has elapsed
	duration = (exercise[exercise.length - 1].time + 1) * opts.noteInterval
	endTimeout = setTimeout ->
		dispatch.complete(data)
	, duration

	# Expose an abort method, which ends the exercise early.
	dispatch.abort = ->
		instrument.stopEmulatingKeys()
		instrument.on('keydown.exercise', null)
		clearTimeout endTimeout

	_.defer -> dispatch.update(data)
	dispatch

Visualizer = (parent, opts) ->
	parent.append('g').attr(class: 'notes')
	timeline = parent.append('line').attr(
		class: 'timeline'
		x1: 0, y1: -9999
		x2: 0, y2: 9999,
		stroke: 'transparent'
	)

	{ width, height, defaultNoteRadius } = _.extend opts, { defaultNoteRadius: 3 }
	{ max, min, abs } = Math

	visualize = (data) ->	
		x = d3.scale.linear()
			.domain(d3.extent(data, (d) -> d.expectedAt))
			.range([0, width])

		y = d3.scale.linear()
			.domain(d3.extent(data, (d) -> d.key))
			.range([height, 0]) # Position higher notes higher up

		update = parent.select('.notes').selectAll('.note').data(data)
		enter = update.enter().append('g').attr(
			class: 'note'
			transform: (d) -> "translate(#{x(d.expectedAt ? d.playedAt)}, #{y(d.key)})"
		)

		enter.append('circle').attr(
			class: 'indicator'
			r: defaultNoteRadius
			fill: '#fff'
			# TODO: #000, opacity 0, y 5
		)

		colorScale = d3.scale.linear()
			.domain([-1000, 0, 1000])
			.range(['#ff0000', '#fff', '#009eff'])
			.interpolate(d3.interpolateLab)
			.clamp(true)

		errorScale = (error) -> max(abs(x(error)), 3)

		update.select('circle').transition().ease('cubic-out').duration(200).attr(
			r: (d) -> _d(d.error); if d.error? then errorScale(d.error) else defaultNoteRadius
			fill: (d) -> if d.error? then colorScale(d.error) else '#fff'
		)


		# notePlayed = (note, time) ->
		# 	note.sel.select('.anim')
		# 		.transition()
		# 		.ease('cubic-out')
		# 		.duration(600)
		# 		.attr('r', 20)
		# 		.attr('fill-opacity', 1e-6)

		# 	err = error(time, startTime + note.offset)

		# 	note.sel.moveToBack()
		# 	note.sel.select('.indicator')
		# 		.transition().ease('cubic-out').duration(200)
		# 		.attr('fill', colorScale(err))
		# 		.attr('r', 3 + Math.abs(err))
		# 	note.pressedAt = time

		# 	Metronome.start(bpm)
		# 	setTimeout Metronome.stop, duration



	visualize.playTimeline = (duration) ->
		timeline.attr(transform: '', stroke: '#fff')
		# How accurate is this, given what we know about Javascript time? [It seems to be doing well enough, empirically.]
		# If we can't have precision, is it better to *not* have a visual cue?
		timeline
			.transition()
			.duration(duration)
			.ease('linear')
			.attr(transform: "translate(#{width}, 0)")

	visualize.stopTimeline = ->
		timeline.attr(stroke: 'transparent')

	visualize
