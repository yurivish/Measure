ascending = _.flatten [
	major(60)
	major(72)
	72 + 12
]

descending = _.flatten [
	major(72).reverse()
	major(60).reverse()
]

exercise = [
	{
		direction: 'ascending'
		notes: ascending.map (key, index) -> { key, index }
	}
	{
		direction: 'descending'
		notes: descending.map (key, index) -> { key, index }
	}
]

# NOTE: This makes it less straightforward to compose new exercises out of sections from others.
exercise.forEach (section, i) ->
	if i
		section.notesBefore = exercise[i - 1].notesBefore + section.notes.length
	else
		section.notesBefore = 0


d exercise

sel = d3.select('#notes').append('g').attr('transform', 'translate(25, 25)')

noteIndicator = sel.append('g')
noteIndicator.append('circle').attr(
	fill: '#333'
	stroke: '#333'
	cx: 900
	cy: 100

)
noteIndicator.append('text').attr(
	'text-anchor': 'middle'
	dy: '.35em'
	fill: '#fff'
	x: 900
	y: 100
)

indicate = (note) ->
	noteIndicator.select('text').text(note)

	noteIndicator.select('circle').attr(
		r: 60
		stroke: '#ccc'
	)
	.interrupt().transition().duration(300).ease('cubic-out')
	.attr(
		r: 50
		stroke: '#333'
	)

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

	i = 1
	d3.select('body').on('keypress', ->

		w = 800
		p = 1
		s = w / 8 - p
		note = d3.select('.note:nth-child(' + i++ + ')')
		indicate(note.select('text').text())

		note.select('.after')
			.transition().duration(300).ease('cubic-out')
			.attr(height: s, y: 0)

		note.select('text')
			.transition().duration(300).ease('cubic-out')
			.attr('fill', '#000')
	)


visSection = (section, i) ->

	w = 800
	p = 1
	s = w / 8 - p

	update = d3.select(this).selectAll('.note').data(section.notes)
	enter = update.enter().append('g').attr(class: 'note')
	# enter.append('circle').attr(r: s / 2, cx: s/2, cy: s/2)
	enter.append('rect').attr(height: s, width: s, class: 'before', fill: '#343434')
	enter.append('rect').attr(height: 0, width: s, class: 'after', y: s, fill: '#ccc')
	enter.append('text').attr('text-anchor': 'middle', x: s/2, y: s/2, dy: '.35em', fill: '#ddd')
		.text(-> ['C', 'D', 'E', 'F#'][~~(Math.random() * 4)])

	update.attr(
		transform: (d, i) ->
			x = i * (s + p) % w
			y = (s + p) *(~~((i / w) * (s + p)))
			"translate(#{x}, #{y})"
	).on('mouseenter', ->

	)




visExercise exercise