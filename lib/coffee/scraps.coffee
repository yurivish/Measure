

# ex = [72, 74, 76, 77, 79, 77, 76, 74, 72]
# ex.reduce(
# 	(q, ks, i) -> 
# 		if i == 0
# 			q.fcall(-> instr.waitForPress ks)
# 		else
# 			q.then(-> instr.waitForPress ks)
# 	Q
# ).then(->
# 	d 'finished!'
# )

noteIndicator = sel.append('g').attr('transform', 'translate(950, 100)')
noteIndicator.append('circle').attr(
	fill: '#333'
	stroke: '#333'
	r: 50
)
noteIndicator.append('text').attr(
	'text-anchor': 'middle'
	dy: '.35em'
	fill: '#fff'
)

# Idea: Animate notes horizontally, timed so that the ideal playthrough has no animation pauses.

indicate = (note) ->
	noteIndicator.select('text').text(note)
		.attr('transform', 'scale(1.1)')
		.interrupt().transition().duration(600).ease('cubic-out')
		.attr('transform', 'scale(1)')

	noteIndicator.select('circle').attr(
		stroke: '#888'
		# transform: 'scale(1.1)'
	)
	.interrupt().transition().duration(600).ease('cubic-out')
	.attr(
		stroke: '#333'
		# transform: 'scale(1)'
	)



w = 800
px = 0
py = 25
s = w / 8 - px

visExercise = (exercise) ->
	update = sel.selectAll('.section').data(exercise)
	enter = update.enter().append('g').attr(class: 'section')

	heightSoFar = 0

	update
		.each(visSection)
		.attr(
			transform: (d, i) ->
				padding = 25
				offset = heightSoFar
				rect = this.getBoundingClientRect()
				heightSoFar += rect.height + padding
				"translate(0, #{ offset })"
		)

	sel.selectAll('.note')
		.attr(opacity: 1e-6)
		.transition().duration(600)
		.delay((d, i) -> i * 20)
		.attr(opacity: 1)

	rect = sel.node().getBoundingClientRect()
	d3.select('#notes').attr(height: rect.top + rect.height)



visSection = (section, i) ->

	update = d3.select(this).selectAll('.note').data(section.notes)
	enter = update.enter().append('g').attr(class: 'note')
	# enter.append('circle').attr(r: s / 2, cx: s/2, cy: s/2)
	enter.append('rect').attr(height: s, width: s, class: 'before', fill: '#000', stroke: '#333')
	# enter.append('line').attr(x1: s, x2: s, y1: 0, y2: s, stroke: '#333')
	enter.append('rect').attr(height: s, width: 0, class: 'after', fill: '#333')
	enter.append('text').attr('text-anchor': 'middle', x: s/2, y: s/2, dy: '.35em', fill: '#ddd')
		.text(-> ['C', 'D', 'E', 'F#'][~~(Math.random() * 4)])

	update.attr(
		transform: (d, i) ->
			x = i * (s + px) % w
			y = (s + py) *(~~((i / w) * (s + px)))
			"translate(#{x}, #{y})"
	).on('mouseenter', ->

	)


###
i = 1
pressed =  ->

	if i > 1
		prevnote = d3.select('.note:nth-child(' + (i - 1) + ')')
		prevnote.select('.after').interrupt()
		prevnote.select('.before').attr('fill', 'red')


	note = d3.select('.note:nth-child(' + i++ + ')')
	indicate(note.select('text').text())

	note.select('.after').interrupt()
		.transition().duration(400).ease('linear')#.ease('cubic-out')
		.attr(width: -> s - d3.select(this).attr('x'))

	note.select('text')
		.transition().duration(400).ease('linear')#.ease('cubic-out')
		.attr('fill', '#000')
		.attr('fill', '#333')

	# nextnote = d3.select('.note:nth-child(' + i + ')')
	# # nextnote.select('.before')
	# nextnote.select('.after')
	# 	.transition().delay(400).duration(400).ease('linear')#.ease('cubic-out')
	# 	.attr(x: s)


initInstrument()
	.on('keydown', pressed)
	.on('error', (instrumentMissing, err) ->
		if instrumentMissing
			d 'You have no MIDI keyboard.'
		else
			d 'Error initializing MIDI connection:', err
	)

###
