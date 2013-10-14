instrument = initInstrument()


###

	Exercise: List of notes

	Note:
		- Key
		- Time (normalized)


	Time visualization: Visualize beat and note times
		Input: Exercise, BPM, beatSize, noteSize
		Output: A major tick for each beat, and a minor tick for each note

	Exercise visualization: Visualize notes and their errors


	--


###

_.defer ->
	d 'Starting'

	exercise = _.flatten([
		Theory.major(60)
		Theory.major(72)
		72 + 12 # Top C
		72 + 12
		Theory.major(72).reverse()
		Theory.major(60).reverse()
	]).map (key, index, arr) -> {
		key
		time: index # Time starts at zero and is incremented every beat.
		hand: 'left'
	}

	bpm = 120

	beatsPerMeasure = 4
	beatSize = 0.25
	noteSize = 0.0625

	vis = d3.select('#exercise')

	# NOTE: This does not work. The height turns out to be the entire window height. Thought it worked yesterday?
	{ width, height } = vis.node().getBoundingClientRect()
	height = 200
	vis.attr({ width, height: height + 150 })

	pad = 40
	metronomeVis = M.time()
		.beats(Math.ceil exercise.length * (noteSize / beatSize))
		.beatSize(beatSize)
		.noteSize(noteSize)
		.width(width)
		.pad(pad)
		.vis(vis)

	metronomeVis()

	# exerciseVis = M.exercise()
	# 	.width(width)
	# 	.height(height)
	# 	.pad(pad)
	# 	.bpm(bpm)
	# 	.noteSize(noteSize)
	# 	.vis(vis.append('g').attr('transform', 'translate(0, 100)'))

	# ex = null
	# stop = ->
	# 	Metronome.stop() # BUG: seems to stop before the last note is played, sometimes?
	# 	exerciseVis.stopTimeline()
	# 	ex.abort()

	# arm = ->
	# 	ex = start(exercise, bpm, notesPerBeat)
	# 		.on('start', (notes) ->
	# 			exerciseVis.startTimeline(notes[notes.length - 1].expectedAt)
	# 			Metronome.start(bpm)
	# 		).on('update', (notes) -> exerciseVis.notes(notes))
	# 		.on('complete', (notes) ->
	# 			stop()
	# 			d 'Complete.'
	# 		)
	# arm()

	# key 'a', ->
	# 	stop()

	# key 'r', ->
	# 	stop()
	# 	arm()

	# # NOTE: We'll want to record incomplete sessions and aborts, too.
	# And visits to the site.

start = (notes, bpm, notesPerBeat) ->
	dispatch = d3.dispatch 'start', 'update', 'complete'

	# Session data for this instantiation of the notes
	data = notes.map (note) -> {
		key: note.key
		expectedAt: note.time * Theory.timeBetweenNotes(bpm, notesPerBeat)
		playedAt: null
		name: Theory.noteNameForKey note.key, true
	}

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
	# BUG: Ends early...
	duration = noteSize * exercise.length
	endTimeout = setTimeout ->
		dispatch.complete(data)
	, duration * 2 # BUG: Double to compensate for wrong timing ???

	# Expose an abort method to ends the exercise early.
	dispatch.abort = ->
		instrument.stopEmulatingKeys()
		instrument.on('keydown.notes', null)
		clearTimeout endTimeout

	_.defer -> dispatch.update(data)
	dispatch

M = {
	time: ->
		opts = {
			beats: 10
			beatSize: 1
			noteSize: 1
			width: 300
			pad: 0
			vis: null
		}

		createElements = ->
			if opts.vis.select('.time-vis').empty()
				parent = opts.vis.append('g').attr(class: 'time-vis')
				parent.append('g').attr(class: 'axis major')
				parent.append('g').attr(class: 'axis minor')

		render = ->
			duration = opts.beats * opts.beatSize

			x = d3.scale.linear()
				.domain([0, duration])
				.range([opts.pad, opts.width - opts.pad])

			major = d3.svg.axis()
				.scale(x)
				.orient('bottom')
				.tickValues(n for n in [0..duration / opts.beatSize] by opts.beatSize)
				.tickSize(14)

			minor = d3.svg.axis()
				.scale(x)
				.orient('bottom')
				.tickValues(n for n in [0..duration / opts.noteSize] by opts.noteSize)
				.outerTickSize(0)
				.innerTickSize(7)

			parent = opts.vis.select('.time-vis')
			parent.select('.axis.major').call(major)
			parent.select('.axis.minor').call(minor)

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
			noteSize: 0.25
			notes: [ ]
			vis: null
		}

		{ max, min, abs } = Math

		createElements = ->
			vis = opts.vis
			notes = vis.select('.notes')
			if notes.empty()
				notes = vis.append('g').attr('class', 'notes')
				notes.append('g').attr('class', 'contours')
				timeline = vis.append('line').attr(
					class: 'timeline'
					x1: 0, y1: -9999
					x2: 0, y2: 9999,
					stroke: 'transparent'
				)

		render = ->
			data = opts.notes

			data[0].instruction = 'Ascend 2 octaves'
			data[15].instruction = 'Descend 2 octaves'

			# TODO: Do we want to visualize real time, or with bpm normalized out?

			x = d3.scale.linear()
				.domain(d3.extent(data, (d) -> d.expectedAt))
				.range([opts.pad, opts.width - opts.pad])

			y = -> -75

			notes = opts.vis.select('.notes')
			update = notes.selectAll('.note').data(data)
			enter = update.enter().append('g').attr(
				class: 'note'
				transform: (d) -> "translate(#{x(d.expectedAt ? d.playedAt)}, #{y(d.key)})"
			)

			enter.append('rect').attr(
				class: 'indicator'
				fill: '#fff'
				stroke: '#fff' # So that we're completely aligned with the metronome marking
				x: 0
			)

			textY = 30
			instructionY = textY + 20

			enter.append('text').attr(
				class: 'name'
				y: textY
				x: -1 # Compensate for letters not starting immediately at the onset of the character
				fill: (d) -> '#999' #if d.instruction then '#fff' else '#999'
			).text((d) -> if d.instruction then d.name else '')#if d.name[0] == 'C' then d.name else '')


			enter.append('text').attr(
				class: 'instruction'
				y: instructionY
				x: -1 # Compensate for letters not starting immediately at the onset of the character
				fill: '#fff'
			).text((d) -> d.instruction ? '')


			colorScale = d3.scale.linear()
				.domain([-1000, 0, 1000])
				.range(['#ff0000', '#fff', '#009eff'])
				.interpolate(d3.interpolateLab)
				.clamp(true)

			noteHeight = 10
			noteWidth = 3

			errorScale = (error) -> x(error) - x(0)

			update.select('.indicator').transition().ease('cubic-out').duration(0).attr(
				width: (d) -> if d.error? then abs errorScale(d.error) else noteWidth
				height: noteHeight
				x: (d) -> 
					if d.error?
						min 0, errorScale(d.error)
					else
						0
				fill: (d) ->   if d.error? then colorScale(d.error) else '#fff'
				stroke: (d) -> if d.error? then colorScale(d.error) else '#fff'
			)

		render.startTimeline = (duration) ->
			timeline = opts.vis.select('.timeline')
			# How accurate is this, given what we know about Javascript time? [It seems to be doing well enough, empirically.]
			# If we can't have precision, is it better to *not* have a visual cue?
			timeline
				.attr(transform: "translate(#{opts.pad}, 0)", stroke: '#fff')


				# .duration(duration)
			t = timeline
			for i in [0...30]
				t = t.transition().duration(500).delay(i * 500 - 25)
					# .ease('linear')
					.ease('cubic-out')
					.attr(transform: "translate(#{opts.pad + (opts.width - opts.pad) / 30 * i}, 0)")

		render.stopTimeline = ->
			timeline = opts.vis.select('.timeline')
			timeline.interrupt().attr(stroke: 'transparent').transition()

		_.accessors(render, opts).addAll()
			.add('notes', render)
			.add('vis', createElements)
			.done()


}
