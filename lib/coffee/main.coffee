exercise = {
	notes: _.flatten [
		major(60)
		# major(72)
		# 72 + 12 # Top C
		# major(72).reverse()
		60 + 12
		major(60).reverse()
	]
}

d 'Exercise:', exercise

sel = d3.select('#notes')
	.append('g').attr('transform', 'translate(25, 25)')

instrument = initInstrument()


interval = 500
notes = exercise.notes.map (key, index) -> { key, index, start: index * interval }

w = 600
r = w / notes.length / 2 - 5


xpos = d3.scale.linear().domain([0, notes.length]).range([0, w])

timeline = sel.append('line').attr(x1: xpos(0), x2: xpos(notes.length - 1), y1: r * 2, y2: r * 2)
timecircle = sel.append('circle').attr(cx: xpos(0), cy: r * 2, r: 5, fill: '#fff')

update = sel.selectAll('.note').data(notes)
enter = update.enter().append('g').attr(
	class: 'note'
	transform: (d, i) ->
		"translate(#{xpos(i)}, 0)"
)
enter.append('circle').attr(
	r: r
	fill: '#333'
)

colorScale = d3.scale.linear()
	.domain([0, 0.25, 0.5, 0.75, 1])
	.range(['#333', 'blue', '#888', 'red', '#333'])
	.interpolate(d3.interpolateLab)

start = ->
	tag = do (i = 0) -> (s) -> s + '.exercise_' + i++

	update.each (d, i) ->
		if i
			d3.select(this).select('circle')
				.transition()
				.duration(interval)
				.delay(d.start - interval)
				.tween('fill', (d) ->
					pressed = false
					evt = tag('keydown')
					instrument.on(evt, -> pressed = true)
					this.setAttribute 'stroke', '#ccc'

					(t) ->

						if not pressed
							this.setAttribute 'fill', colorScale(t)

						if t == 1
							instrument.on(evt, null)
				)
		else
			d3.select(this).select('circle').attr('fill', colorScale(0.5))

instrument.on('keydown.start', ->
	start()
	timecircle.transition().duration(interval * (notes.length - 1)).ease('linear').attr('cx': xpos(notes.length - 1))
	instrument.on('keydown.start', null)
)
	# .then((data) ->

	# )



# TODO: Investigate high-resolution timers.



# start = ->
# 	for note, i in notes
# 			d3.select(d.el)
# 				.transition().duration(1000).delay()
# 				.attrTween

	# notes = [1, 2, 3]
	# startTime = Date.now() + interval
	# endTime = startTime + (notes.length - 1) * interval
	# notesOverTime = d3.scale.threshold()
	# 	.domain(d3.range(startTime, endTime, interval))
	# 	.range(notes)

	# complete = false
	# d3.timer ->
	# 	now = Date.now()
	# 	d 'Note:', notesOverTime(now)
	# 	complete = now > endTime
	#	complete

