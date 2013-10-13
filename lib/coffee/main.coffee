instrument = initInstrument()


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
		degree: if index < arr.length/2 then index else (arr.length - index) - 1
		hand: 'left'
	}

	bpm = 120
	noteDuration = 1 # Whole notes

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
		.noteDuration(noteDuration)
		.vis(vis.append('g').attr('transform', 'translate(0, 100)'))

	ex = null
	stop = ->
		Metronome.stop() # BUG: seems to stop before the last note is played, sometimes?
		exerciseVis.stopTimeline()
		ex.abort()

	arm = ->
		ex = start(exercise, bpm, noteDuration)
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

start = (notes, bpm, noteDuration) ->
	dispatch = d3.dispatch 'start', 'update', 'complete'

	# Session data for this instantiation of the notes
	data = notes.map (note) -> {
		key: note.key
		degree: note.degree
		expectedAt: note.time * Theory.timeBetweenNotes(bpm, noteDuration)
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
	duration = (notes[notes.length - 1].time) * Theory.timeBetweenNotes(bpm, noteDuration)
	endTimeout = setTimeout ->
		dispatch.complete(data)
	, duration * 2 # BUG: Double to compensate for wrong timing

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
			noteDuration: 1
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
				transform: (d) -> "translate(#{x(d.expectedAt ? d.playedAt)}, #{y(d.degree)})"
			)

			enter.append('rect').attr(
				class: 'indicator'
				fill: '#fff'
				stroke: '#fff' # So that we're completely aligned with the metronome marking
				x: 0
			)

			textY = 30

			enter.append('text').attr(
				class: 'name'
				y: textY
				x: -1 # Compensate for letters not starting immediately at the onset of the character
				fill: (d) -> if d.instruction then '#fff' else '#999'
			).text((d) -> if d.name[0] == 'C' then d.name else '')


			enter.append('text').attr(
				class: 'instruction'
				y: textY + 20
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

			# Pitch contours	
			# Idea: Pitch contour only places where change occurs, e.g. the first upwards note, and the first downwards note
			# update = notes.select('.contours').selectAll('.contour').data(data[...data.length - 1])
			# contourY = textY - 5 # - half text height

			# enter = update.enter().append('line').attr(
			# 	class: 'contour'
			# 	x1: (d, i) -> x(d.expectedAt) + 15
			# 	x2: (d, i) -> x(data[i+1].expectedAt) - 15
			# 	y1: (d, i) -> y(d.degree) + contourY - if data[i+1].degree - d.degree < 0 then 3 else -3
			# 	y2: (d, i) -> y(d.degree) + contourY - if data[i+1].degree - d.degree > 0 then 3 else -3
			# 	stroke: '#666'
			# )

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
