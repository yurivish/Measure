instrument = initInstrument()


_.defer ->
	d 'Starting'

	exercise = _.flatten([
		Theory.major(60)
		Theory.major(72)
		72 + 12 # Top C
		Theory.major(72).reverse()
		Theory.major(60).reverse()
	]).map (key, index, arr) -> {
		key
		time: index # Time starts at zero and is incremented every beat.
		degree: if index < arr.length/2 then index else (arr.length - index) - 1
		hand: 'left'
	}

	bpm = 120
	noteSize = 1 # Whole notes

	vis = d3.select('#exercise')

	# NOTE: This does not work. The height turns out to be the entire window height. Thought it worked yesterday?
	{ width, height } = vis.node().getBoundingClientRect()
	height = 200
	vis.attr({ width, height: height + 150 })

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
		.vis(vis.append('g').attr('transform', 'translate(0, 100)'))

	ex = null
	stop = ->
		Metronome.stop() # BUG: seems to stop before the last note is played, sometimes?
		exerciseVis.stopTimeline()
		ex.abort()

	arm = ->
		ex = start(exercise, bpm, noteSize)
			.on('start', (notes) ->
				exerciseVis.startTimeline(notes[notes.length - 1].expectedAt)
				Metronome.start(bpm)
			).on('update', (notes) -> exerciseVis.notes(notes))
			.on('complete', (notes) ->
				stop()
				d 'Complete.'
			)
	arm()

	key 'a', ->
		stop()

	key 'r', ->
		stop()
		arm()

	# # NOTE: We'll want to record incomplete sessions and aborts, too.
	# And visits to the site.

start = (notes, bpm, noteSize) ->
	dispatch = d3.dispatch 'start', 'update', 'complete'

	# Session data for this instantiation of the notes
	data = notes.map (note) -> {
		key: note.key
		degree: note.degree
		expectedAt: note.time * Theory.timeBetweenNotes(bpm, noteSize)
		playedAt: null
		name: Theory.noteNameForKey note.key 
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
				playedAt: time			# # enter.append('text').attr(
			# # 	y: 30
			# # 	fill: '#999'
			# # ).text((d) -> d.text)

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
			if opts.vis.select('.metronome').empty()
				nome = opts.vis.append('g').attr(class: 'metronome')
				nome.append('g').attr(class: 'axis major')
				nome.append('g').attr(class: 'axis minor')

		render = ->
			beats = [ ]
			majors = [ ]
			minors = [ ]
			for num in [0...opts.beats]
				# NOTE: Notes and beats are not one-to-one.
				# TODO: Should have real text or perhaps just the first and last have timing info
				beats.push { num } 
				majors.push num
				unless num == opts.beats - 1
					minors.push num + 0.25
					minors.push num + 0.5
					minors.push num + 0.75

			beatRadius = (d, i) ->  if i % 4 then 2 else 6

			x = d3.scale.linear()
				.domain([0, opts.beats - 1])
				.range([opts.pad, opts.width - opts.pad])

			major = d3.svg.axis()
				.scale(x)
				.orient('bottom')
				.tickValues(majors)
				.tickSize(14)

			minor = d3.svg.axis()
				.scale(x)
				.orient('bottom')
				.tickValues(minors)
				.outerTickSize(0)
				.innerTickSize(7)

			nome = opts.vis.select('.metronome')
			nome.select('.axis.major').call(major)
			nome.select('.axis.minor').call(minor)

			# update = nome.selectAll('.beat').data(beats)
			# enter = update.enter().append('g').attr(
			# 	class: 'beat'
			# 	transform: (d) -> "translate(#{x(d.num)}, 25)" # TODO: - beatRadius(d, i)
			# 	opacity: 1e-6
			# )
			# enter.append('circle').attr(
			# 	r: beatRadius
			# 	fill: '#999'
			# )
			# # enter.append('text').attr(
			# # 	y: 30
			# # 	fill: '#999'
			# # ).text((d) -> d.text)

			# update.transition()
			# 	.delay((d, i) -> i * 10)
			# 	.duration(500)
			# 	.ease('ease-out-expo')
			# 	.attr({
			# 		opacity: 1

			# 	})
			# update.exit().remove()

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
				.domain(d3.extent(data, (d) -> d.degree))
				.range([opts.height, 0]) # Position higher notes higher up

			y = -> -75

			update = opts.vis.select('.notes').selectAll('.note').data(data)
			enter = update.enter().append('g').attr(
				class: 'note'
				transform: (d) -> "translate(#{x(d.expectedAt ? d.playedAt)}, #{y(d.degree)})"
			)

			enter.append('rect').attr(
				class: 'indicator'
				fill: '#fff'
				x: 0
			)

			enter.append('text').attr(
				y: 30
				fill: '#999'
			).text((d) -> d.name)


			colorScale = d3.scale.linear()
				.domain([-1000, 0, 1000])
				.range(['#ff0000', '#fff', '#009eff'])
				.interpolate(d3.interpolateLab)
				.clamp(true)

			noteHeight = 10
			noteWidth = 2

			errorScale = (error) -> x(error) - x(0)


			update.select('.indicator').transition().ease('cubic-out').duration(0).attr(
				width: (d) -> if d.error? then abs errorScale(d.error) else noteWidth
				height: noteHeight
				x: (d) -> 
					if d.error?
						min 0, errorScale(d.error)
					else
						0
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
