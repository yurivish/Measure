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
			{ from: 0,  to: 14, text: 'Ascend 2 octaves'}
			{ from: 15, to: 29, text: 'Descend 2 octaves'}
		]

		beatsPerMeasure: 4 				# Numerator of time signature
		beatSize: 0.25 					# Denominator of time signature
		noteSize: 0.125					# Indirectly specifies the number of notes in a beat
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

	loadSequence(sequence)

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
				transform: (d) -> "translate(#{x(d.index * seq.noteSize)}, #{y()})"
			)

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
			annKeyLabel = (type) ->
				enter.append('text').attr(
					class: type + '-key'
					transform: (d) -> "translate(#{xAnn(d, type)}, #{yAnn()})"
				).text((d) -> Theory.nameForKey notes[d.from].key, true).each -> this.parentNode[type + 'Key'] = this
			
			# Label 'to' and 'from' keys
			annKeyLabel 'to'
			annKeyLabel 'from'

			pad = 10
			enter.append('line').attr(
				x1: (d) -> xAnn(d, 'from') + this.parentNode.fromKey.getComputedTextLength() + pad
				x2: (d) -> xAnn(d, 'to') - pad
				y1: (d) -> yAnn() - 4 # Tweaked for 12px labels.
				y2: (d) -> yAnn() - 4
				stroke: '#555'
			)

			enter.append('text').attr(
				transform: (d) -> "translate(#{x(notes[d.from].index * seq.noteSize) - 2}, #{yAnn() + 20})"
			).text((d) -> d.text)

		_.accessors(render, opts).addAll()
			.add('vis', createElements)
			.add('seq', render)
			.done()

}
