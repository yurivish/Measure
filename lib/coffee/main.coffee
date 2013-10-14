instrument = initInstrument()

_.defer ->
	d 'Starting'

	vis = d3.select('#piece')

	# NOTE: This does not work. The height turns out to be the entire window height. Thought it worked yesterday..?
	{ width, height } = vis.node().getBoundingClientRect()
	height = 200
	vis.attr({ width, height: height + 150 })

	sequence = {
		notes: _.flatten([
			Theory.major(60)
			Theory.major(72)
			72 + 12 # Top C
			72 + 12
			Theory.major(72).reverse()
			Theory.major(60).reverse()
		]).map (key, index) -> {
			key
			index
		}

		annotations: [
			{ from: 0,  to: 14, text: 'Ascend'}
			{ from: 15, to: 29, text: 'Descend'}
		]

		beatsPerMeasure: 4 		# Numerator of time signature
		beatSize: 0.25 			# Denominator of time signature
		noteSize: 0.125			# Indirectly specifies the number of notes in a beat
	}
	sequence.beats = Math.ceil sequence.notes.length * (sequence.noteSize / sequence.beatSize)

	loadSequence = (seq) ->
		pad = 40
		bpm = 120
		timeVis = M.time()
			.beats(seq.beats)
			.beatSize(seq.beatSize)
			.noteSize(seq.noteSize)
			.bpm(bpm)
			.width(width)
			.pad(pad)
			.vis(vis.append('g').attr('class', 'time-vis'))

		timeVis()

		errorVis = M.error()
			.width(width)
			.pad(pad)
			.bpm(bpm)
			.vis(vis.append('g').attr('class', 'error-vis'))
			.seq(seq)

		sequenceVis = M.sequence()
			.width(width)
			.pad(pad)
			.bpm(bpm)
			.vis(vis.append('g').attr('class', 'seq-vis'))
			.seq(seq)

		sequenceVis()


		start(seq, bpm)
			.on('start', (played) -> d 'start')
			.on('update', (played) -> errorVis.played(played))
			.on('end', -> d 'end')

	_.defer -> loadSequence(sequence)

	start = (seq, bpm) ->
		dispatch = d3.dispatch 'start', 'update', 'end'

		played = [ ]
		alreadyPlayed = { }

		noteIndexToBeatTime = d3.scale.linear()
			.domain([0, seq.notes.length])
			# .range([0, seq.beats * seq.beatSize])
			.range([0, seq.notes.length * seq.noteSize])

		noteIndexToTime = d3.scale.linear()
			.domain([0, seq.notes.length])	
			.range([0, (1 / bpm) * 60 * 1000 * seq.notes.length]) #seq.beats * 1000 * 60 * (1 / bpm)])

		startTime = null # Determined from the first keydown event
		instrument.on 'keydown.notes', (e) ->
			unless startTime?
				startTime = e.time
				dispatch.start(played)

			time = e.time - startTime
			index = findCorrespondingIndex e.key, time
			if index?
				alreadyPlayed[index] = true
				note = seq.notes[index]
				expectedMs = noteIndexToTime(note.index)
				expectedBeats = noteIndexToBeatTime(note.index)
				playedMs = time
				playedBeats = noteIndexToBeatTime noteIndexToTime.invert(time)
				errorMs = playedMs - expectedMs
				errorBeats = playedBeats - expectedBeats
				d errorMs
				played.push {
					key: e.key
					expectedMs, expectedBeats
					playedMs, playedBeats
					errorMs, errorBeats
				}
			else
				0
				# TODO: Something sensible
				# played.push {
				# 	key: e.key
				# 	expectedAt: null
				# 	playedAt: time
				# }
			# d(played...)
			dispatch.update(played)

		findCorrespondingIndex = (key, time) ->
			# Return the corresponding note from the piece, or null if we didn't find one.
			# For now, scan linearly through the list, taking the closest unplayed matching note
			# within a temporal window. If there are several close-by notes, prefer the earliest
			# one inside the window.
			# NOTE: Extra notes end up at the back, unsorted. We'll want to revise this when we 
			# implement binary search.
			timeWindow = 2000
			for note in seq.notes
				# break unless note.playedAt? # Never skip past an unplayed note
				# If the note matches, was expected, hasn't been played, and is in our window, return it.
				if note.index of alreadyPlayed
					continue
				else if note.key == key and Math.abs(noteIndexToTime(note.index) - time) < timeWindow
					return note.index
			return null

		instrument.emulateKeysWithKeyboard seq.notes.map ({key}) -> key

		# TODO: End!

		# # End the piece once the amount of time that it takes has elapsed
		# # BUG: Ends early...
		# duration = noteSize * piece.length
		# endTimeout = setTimeout ->
		# 	dispatch.complete(data)
		# , duration * 2 # BUG: Double to compensate for wrong timing ???

		# Expose an abort method to ends the piece early.
		dispatch.abort = ->
			instrument.stopEmulatingKeys()
			instrument.on('keydown.notes', null)
			# clearTimeout endTimeout

		_.defer -> dispatch.update(played)
		dispatch

M = {
	noteTop: 60 # 35
	noteHeight: 15

	time: ->
		opts = {
			width: 300
			pad: 0
			beats: 11 		# Number of beats to visualize
			beatSize: 0.25 	# Denominator of time signature; used for major ticks
			noteSize: 0.25 	# Base size of a note; used for minor ticks
			bpm: 120		# Beats per minute
			vis: null
		}

		x = d3.scale.linear()

		# One major tick per beat
		major = d3.svg.axis()
			.scale(x)
			.orient('bottom')
			.tickSize(14)

		# One minor tick per note
		minor = d3.svg.axis()
			.scale(x)
			.orient('bottom')
			.outerTickSize(0)
			.innerTickSize(7)

		render = ->
			# Scale from beat time to horizontal space
			duration = opts.beats * opts.beatSize
			x
				.domain([0, duration])
				.range([opts.pad, opts.width - opts.pad])

			# Create axis parent elements if they don't exist
			vis = opts.vis
			if vis.select('.axis.major').empty()
				vis.append('g').attr(class: 'axis major')
				vis.append('g').attr(class: 'axis major')
				vis.append('g').attr(class: 'axis minor')

			vis.select('.axis.major').call major.tickValues(n for n in [0..duration / opts.beatSize] by opts.beatSize)
			vis.select('.axis.minor').call minor.tickValues(n for n in [0..duration / opts.noteSize] by opts.noteSize)

		_.accessors(render, opts)
			.addAll()
			.done()

	error: ->
		opts = {
			width: 300
			pad: 0
			bpm: 120
			vis: null
			seq: null
			played: null
		}

		colorScale = d3.scale.linear()
			.domain([-50, 0, 50])
			.range(['#009eff', '#fff', '#ff0000'])
			.interpolate(d3.interpolateLab)
			.clamp(true)

		color = (d) ->

			switch
				when Math.abs(d.errorMs) < 10
					'#00fa00'
				when d.errorMs < 0
					'#ff0012'
				else
					'#00b6ff'

			colorScale(d.errorMs)


		render = ->
			seq = opts.seq
			played = opts.played

			# Scale from beat time to horizontal space
			duration = seq.beats * seq.beatSize
			x = d3.scale.linear()
				.domain([0, duration])
				.range([opts.pad, opts.width - opts.pad])

			# expectedMs, expectedBeats
			# playedMs, playedBeats
			# errorMs, errorBeats

			update = opts.vis.selectAll('.note').data(played)
			enter = update.enter().append('g').attr('class', 'note')

			# Rectangles embedded between notes
			# enter.append('rect').attr(
			# 	x: (d) -> Math.round x(d.expectedBeats + d.errorBeats) + if d.errorBeats > 0 then -(x(d.errorBeats) - x(0)) else 0
			# 	y: M.noteTop
			# 	width: (d) -> Math.max 1, Math.abs x(d.errorBeats) - x(0)
			# 	height: M.noteHeight
			# 	stroke: color
			# 	fill: color
			# )

			# Rectangles below axes but above notes
			# enter.append('rect').attr(
			# 	# x: (d) -> Math.round x(d.expectedBeats)
			# 	x: (d) -> Math.round x(d.expectedBeats)
			# 	y: 30
			# 	height: 14
			# 	# y: M.noteTop
			# 	# height: M.noteHeight
			# 	width: 0
			# 	fill: color
			# ).transition().ease('exp-out').duration(350).attr(
			# 	width: x(seq.noteSize) - x(0) + .5
			# )

			# Lines with a circle between 'em'
			# lo = 0#14
			# hi = M.noteTop
			# mid = (lo + hi) / 2
			# enter.append('circle').attr(
			# 	cx: (d) -> x(d.expectedBeats + d.errorBeats)
			# 	cy: mid
			# 	r: 3
			# 	fill: color
			# )
			# enter.append('line').attr(
			# 	x1: (d) -> x(d.expectedBeats)
			# 	x2: (d) -> x(d.expectedBeats + d.errorBeats)
			# 	y1: lo
			# 	y2: mid
			# 	stroke: color
			# )
			# enter.append('line').attr(
			# 	x1: (d) -> x(d.expectedBeats)
			# 	x2: (d) -> x(d.expectedBeats + d.errorBeats)
			# 	y1: hi
			# 	y2: mid
			# 	stroke: color
			# )

			# Filled polygon version of the above
			# enter.append('polygon').attr(
			# 	points: (d) -> [
			# 		x(d.expectedBeats), lo
			# 		x(d.expectedBeats + d.errorBeats), mid	
			# 		x(d.expectedBeats), hi
			# 	].join(',')
			# 	fill: color
			# )

			enter.append('line').attr(
				x1: (d) -> x(d.expectedBeats)
				x2: (d) -> x(d.expectedBeats + seq.noteSize)
				y1: (d) -> 30 - d.errorMs / 50
				y2: (d) -> 30 + d.errorMs / 50
				stroke: color
			)

			update.exit().remove()

		_.accessors(render, opts).addAll()
			.add('played', render)
			.done()

	sequence: ->
		opts = {
			width: 300
			pad: 0
			bpm: 120
			vis: null
			seq: null
		}

		render = ->
			seq = opts.seq
			notes = seq.notes

			# Scale from beat time to horizontal space
			duration = seq.beats * seq.beatSize
			x = d3.scale.linear()
				.domain([0, duration])
				.range([opts.pad, opts.width - opts.pad])

			y = -> M.noteTop

			update = opts.vis.selectAll('.note').data(notes)
			enter = update.enter().append('g').attr(
				class: 'note'
				transform: (d) -> "translate(#{Math.round x(d.index * seq.noteSize)}, #{y()})"
			)
			update.exit().remove()

			enter.append('rect').attr(
				width: 4
				height: M.noteHeight
				fill: '#fff'
				stroke: '#fff' # Align with the time markings
			)

			# Annotations
			update = opts.vis.selectAll('.annotation').data(seq.annotations)
			enter = update.enter().append('g').attr(
				class: 'annotation'
			)

			xAnn = (d, type) -> x(notes[d[type]].index * seq.noteSize) - 2 # Subtract two to visually align with the note above
			yAnn = -> y() + 40

			# Label 'to' and 'from' keys
			annKeyLabel = (type) ->
				enter.append('text').attr(
					class: type + '-key'
					transform: (d) -> "translate(#{xAnn(d, type)}, #{yAnn()})"
				).text((d) -> Theory.nameForKey notes[d[type]].key, true).each -> this.parentNode[type + 'Key'] = this
			
			annKeyLabel 'to'
			annKeyLabel 'from'

			# Draw a line between the labels
			keyLabelPadding = 10
			enter.append('line').attr(
				x1: (d) -> xAnn(d, 'from') + this.parentNode.fromKey.getComputedTextLength() + keyLabelPadding
				x2: (d) -> xAnn(d, 'to') - keyLabelPadding
				y1: (d) -> yAnn() - 4 # Tweaked for 12px labels.
				y2: (d) -> yAnn() - 4
				stroke: '#555'
			)

			# Main annotation text (e.g. 'Ascend')
			enter.append('text').attr(
				transform: (d) -> "translate(#{xAnn(d, 'from')}, #{yAnn() + 20})"
			).text((d) -> d.text)

		_.accessors(render, opts).addAll()
			.add('seq', render)
			.done()

}
