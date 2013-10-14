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

		beatsPerMeasure: 4 				# Numerator of time signature
		beatSize: 0.25 					# Denominator of time signature
		noteSize: 0.25					# Indirectly specifies the number of notes in a beat
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
			.vis(vis)

		timeVis()

		sequenceVis = M.sequence()
			.width(width)
			.pad(pad)
			.bpm(bpm)
			.vis(vis)
			.seq(seq)

		sequenceVis()

		errorVis = M.error()
			.width(width)
			.pad(pad)
			.bpm(bpm)
			.vis(vis)
			.seq(seq)

		start(seq, bpm)
			.on('start', (played) -> d 'start')
			.on('update', (played) -> errorVis.played(played))
			.on('end', -> d 'end')

	_.defer -> loadSequence(sequence)

	start = (seq, bpm) ->
		dispatch = d3.dispatch 'start', 'update', 'end'

		played = [ ]
		alreadyPlayed = { }

		startTime = null # Determined from the first keydown event

		noteIndexToBeatTime = d3.scale.linear()
			.domain([0, seq.notes.length])
			.range([0, seq.beats * seq.beatSize])

		noteIndexToTime = d3.scale.linear()
			.domain([0, seq.notes.length])	
			.range([0, seq.beats * 1000 * 60 * (1 / bpm)])

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
				playedMs = noteIndexToTime noteIndexToTime.invert(time)
				playedBeats = noteIndexToBeatTime noteIndexToTime.invert(time)
				errorMs = playedMs - expectedMs
				errorBeats = playedBeats - expectedBeats
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
			d(played...)
			dispatch.update(played)

		findCorrespondingIndex = (key, time) ->
			# Return the corresponding note from the piece, or null if we didn't find one.
			# For now, scan linearly through the list, taking the closest unplayed matching note
			# within a temporal window. If there are several close-by notes, prefer the earliest
			# one inside the window.
			# NOTE: Extra notes end up at the back, unsorted. We'll want to revise this when we 
			# implement binary search.
			timeWindow = 2000
			for note, index in seq.notes
				# break unless note.playedAt? # Never skip past an unplayed note
				# If the note matches, was expected, hasn't been played, and is in our window, return it.
				if index of alreadyPlayed
					continue
				else if note.key == key and Math.abs(noteIndexToTime(index) - time) < timeWindow
					return index
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
	time: ->
		opts = {
			width: 300
			pad: 0
			beats: 10 		# Number of beats to visualize
			beatSize: 0.25 	# Denominator of time signature; used for major ticks
			noteSize: 0.25 	# Base size of a note; used for minor ticks
			bpm: 120		# Beats per minute
			vis: null
		}

		# TODO:Create the parent elements beforehand; pass them into vis. Only create internal elements here.
		# Enables setting translations easily from outside.
		createElements = ->
			if opts.vis.select('.time-vis').empty()
				parent = opts.vis.append('g').attr(class: 'time-vis')
				parent.append('g').attr(class: 'axis major')
				parent.append('g').attr(class: 'axis minor')

		render = ->
			# Scale from beat time to horizontal space
			duration = opts.beats * opts.beatSize
			x = d3.scale.linear()
				.domain([0, duration])
				.range([opts.pad, opts.width - opts.pad])

			# One major tick per beat
			major = d3.svg.axis()
				.scale(x)
				.orient('bottom')
				.tickValues(n for n in [0..duration / opts.beatSize] by opts.beatSize)
				.tickSize(14)

			# One minor tick per note
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

	error: ->
		opts = {
			width: 300
			pad: 0
			bpm: 120
			vis: null
			seq: null
			played: null
		}

		createElements = ->
			if opts.vis.select('.error-vis').empty()
				opts.vis.append('g').attr('class', 'error-vis')

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

			update = opts.vis.select('.error-vis').selectAll('.note').data(played)
			enter = update.enter().append('g').attr('class', 'note')
			enter.append('rect').attr(
				x: (d) -> x(d.expectedBeats) + if d.errorBeats > 0 then -(x(d.errorBeats) - x(0)) else 0
				y: 15
				width: (d) -> Math.abs x(d.errorBeats) - x(0)
				height: 10
				fill: (d) -> if d.errorBeats < 0 then '#ff0000' else '#009eff'
				stroke: (d) -> if d.errorBeats < 0 then '#ff0000' else '#009eff'
			)
			update.exit().remove()

		_.accessors(render, opts).addAll()
			.add('vis', createElements)
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

		createElements = ->
			if opts.vis.select('.seq-vis').empty()
				opts.vis.append('g').attr('class', 'seq-vis')

		render = ->
			seq = opts.seq
			notes = seq.notes

			# Scale from beat time to horizontal space
			duration = seq.beats * seq.beatSize
			x = d3.scale.linear()
				.domain([0, duration])
				.range([opts.pad, opts.width - opts.pad])

			y = -> 35

			update = opts.vis.select('.seq-vis').selectAll('.note').data(notes)
			enter = update.enter().append('g').attr(
				class: 'note'
				transform: (d) -> "translate(#{Math.round x(d.index * seq.noteSize)}, #{y()})"
			)
			update.exit().remove()

			enter.append('rect').attr(
				width: 4
				height: 10
				fill: '#fff'
				stroke: '#fff' # Align with the time markings
			)

			# Annotations
			update = opts.vis.select('.seq-vis').selectAll('.annotation').data(seq.annotations)
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
			.add('vis', createElements)
			.add('seq', render)
			.done()

}
