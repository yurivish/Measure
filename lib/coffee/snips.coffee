
###  ###
###  ###
###  ###
###  ###

### Error visualizations ###
# Tasteful axis-like indicators
enter.append('rect').attr(
	# x: (d) -> Math.round x(d.expectedBeats)
	x: (d) -> Math.round x(d.expectedBeats + d.errorBeats)
	y: 0
	height: 14
	width: 1
	fill: colorGrad
)
enter.append('rect').attr(
	# x: (d) -> Math.round x(d.expectedBeats)
	x: (d) -> Math.round x(d.expectedBeats)
	y: 0
	height: 14
	width: 1
	fill: '#fff'
)

# Rectangles below axes but above notes
enter.append('rect').attr(
	# x: (d) -> Math.round x(d.expectedBeats)
	x: (d) -> Math.round x(d.expectedBeats)
	y: 30
	height: 14
	# y: M.noteTop
	# height: M.noteHeight
	width: 0
	fill: colorGrad
).transition().ease('exp-out').duration(350).attr(
	width: x(seq.noteSize) - x(0) + .5
)

# Lines with a circle between 'em'
lo = 0#14
hi = M.noteTop
mid = (lo + hi) / 2
enter.append('circle').attr(
	cx: (d) -> x(d.expectedBeats + d.errorBeats)
	cy: mid
	r: 3
	fill: colorGrad
)
enter.append('line').attr(
	x1: (d) -> x(d.expectedBeats)
	x2: (d) -> x(d.expectedBeats + d.errorBeats)
	y1: lo
	y2: mid
	stroke: colorGrad
)
enter.append('line').attr(
	x1: (d) -> x(d.expectedBeats)
	x2: (d) -> x(d.expectedBeats + d.errorBeats)
	y1: hi
	y2: mid
	stroke: colorGrad
)

# Filled polygon version of the above
enter.append('polygon').attr(
	points: (d) -> [
		x(d.expectedBeats), lo
		x(d.expectedBeats + d.errorBeats), mid	
		x(d.expectedBeats), hi
	].join(',')
	fill: colorGrad
)

# Try to maintain a straight line! (line)
enter.append('line').attr(
	x1: (d) -> x(d.expectedBeats)
	x2: (d) -> x(d.expectedBeats + seq.noteSize)
	y1: (d) -> 30 - d.errorMs / 50
	y2: (d) -> 30 + d.errorMs / 50
	stroke: colorGrad
)

